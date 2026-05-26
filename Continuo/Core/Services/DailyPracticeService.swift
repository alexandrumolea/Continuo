import Foundation
import FirebaseFirestore

final class DailyPracticeService {
    static let shared = DailyPracticeService()
    private let db = Firestore.firestore()

    // "yyyy-MM-dd" for a given date; defaults to today
    private func dateKey(from date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func todayKey() -> String { dateKey() }

    // Subcollection path: users/{userId}/dailyCompletions/{practiceId}_{dateKey}
    private func completionRef(userId: String, practiceId: String) -> DocumentReference {
        db.collection("users").document(userId)
            .collection("dailyCompletions")
            .document("\(practiceId)_\(todayKey())")
    }

    // MARK: - Real-time listener: returns set of practiceIds completed today
    // Filters by document ID suffix (_dateKey) to avoid requiring a Firestore composite index
    func completedTodayListener(
        userId: String,
        onChange: @escaping (Set<String>) -> Void
    ) -> ListenerRegistration {
        let today = todayKey()
        return db.collection("users").document(userId)
            .collection("dailyCompletions")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ completedTodayListener: \(error.localizedDescription)")
                }
                let ids = Set(
                    snapshot?.documents
                        .filter { $0.documentID.hasSuffix("_\(today)") }
                        .compactMap { $0.data()["practiceId"] as? String } ?? []
                )
                onChange(ids)
            }
    }

    // MARK: - Delete a daily completion (reactivates the card for that day)
    func deleteCompletion(userId: String, practiceId: String, date: Date) async throws {
        let key = dateKey(from: date)
        try await db.collection("users").document(userId)
            .collection("dailyCompletions")
            .document("\(practiceId)_\(key)")
            .delete()
    }

    // MARK: - Update responses on an existing completion
    func update(event: JourneyEvent, responses: [String], userId: String) throws {
        guard let eventId = event.id,
              let practiceId = event.practiceId else { return }

        let dateKey = dateKey(from: event.createdAt)
        let batch = db.batch()

        // Update journeyEvent
        let eventRef = db.collection("journeyEvents").document(eventId)
        batch.updateData(["responses": responses], forDocument: eventRef)

        // Update dailyCompletions record
        let completionRef = db.collection("users").document(userId)
            .collection("dailyCompletions")
            .document("\(practiceId)_\(dateKey)")
        batch.updateData(["responses": responses], forDocument: completionRef)

        batch.commit()
    }

    // MARK: - Complete a practice (idempotent — doc ID includes date, so re-submitting same day overwrites)
    func complete(practice: DailyPractice, responses: [String], userId: String) throws {
        let today = todayKey()
        let batch = db.batch()

        // 1. Save completion record
        let completionRef = db.collection("users").document(userId)
            .collection("dailyCompletions")
            .document("\(practice.id)_\(today)")
        batch.setData([
            "practiceId":    practice.id,
            "practiceTitle": practice.title,
            "responses":     responses,
            "completedAt":   Timestamp(date: Date()),
            "dateKey":       today
        ], forDocument: completionRef)

        // 2. Award GP
        let userRef = db.collection("users").document(userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(practice.gpReward))], forDocument: userRef)

        // 3. Journey event
        let eventRef = db.collection("journeyEvents").document()
        let event = JourneyEvent(
            userId: userId,
            type: .dailyPracticeCompleted,
            title: "\(practice.emoji) \(practice.title)",
            subtitle: practice.prompts.first ?? "",
            gpEarned: practice.gpReward,
            createdAt: Date(),
            practiceId: practice.id,
            responses: responses
        )
        try batch.setData(from: event, forDocument: eventRef)

        batch.commit()

        // Award competency points in background (fire-and-forget)
        if let competencyId = practice.competencyId {
            Task {
                try? await CompetencyService.shared.addPoints(
                    userId: userId,
                    competencyId: competencyId,
                    points: practice.gpReward
                )
            }
        }
    }
}
