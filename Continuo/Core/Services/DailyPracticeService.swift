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

    // MARK: - Live mindfulness minutes today (drives the home card subtitle)
    func mindfulnessTodayListener(userId: String, onChange: @escaping (Int) -> Void) -> ListenerRegistration {
        let today = todayKey()
        return db.collection("users").document(userId)
            .collection("dailyCompletions")
            .document("mindfulness_\(today)")
            .addSnapshotListener { snap, _ in
                onChange((snap?.data()?["minutes"] as? Int) ?? 0)
            }
    }

    // MARK: - One-shot fetch of completed practice IDs for any given date
    func fetchCompletions(userId: String, date: Date) async -> Set<String> {
        let key = dateKey(from: date)
        do {
            let snap = try await db.collection("users").document(userId)
                .collection("dailyCompletions")
                .getDocuments()
            return Set(
                snap.documents
                    .filter { $0.documentID.hasSuffix("_\(key)") }
                    .compactMap { $0.data()["practiceId"] as? String }
            )
        } catch {
            print("❌ fetchCompletions: \(error.localizedDescription)")
            return []
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

    // MARK: - Roll back competency points when a completion is removed
    func rollbackCompetencyPoints(userId: String, practiceId: String, points: Int) async {
        guard points > 0,
              let competencyId = DailyPractice.catalog.first(where: { $0.id == practiceId })?.competencyId else { return }
        try? await CompetencyService.shared.addPoints(
            userId: userId,
            competencyId: competencyId,
            points: -points
        )
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

    // MARK: - Mindfulness — tiered GP (3 GP at ≥5 min, 5 GP at ≥10 min)

    /// Updates today's mindfulness minutes total and awards the GP delta (if any).
    /// Idempotent: minutes can only increase, GP is only awarded once per tier.
    /// Returns the GP delta awarded by this call.
    @discardableResult
    func updateMindfulnessTotal(userId: String, minutesToday: Int) async throws -> Int {
        let today = todayKey()
        let docRef = db.collection("users").document(userId)
            .collection("dailyCompletions")
            .document("mindfulness_\(today)")

        let snap = try await docRef.getDocument()
        let currentMinutes = (snap.data()?["minutes"] as? Int) ?? 0
        let currentGP = (snap.data()?["gpAwarded"] as? Int) ?? 0

        let newMinutes = max(currentMinutes, minutesToday)
        // Don't create empty docs (avoid marking the home card as completed when nothing was logged)
        guard newMinutes > 0 else { return 0 }
        let newGP: Int = {
            if newMinutes >= 10 { return 5 }
            if newMinutes >= 5  { return 3 }
            return 0
        }()
        let gpDelta = newGP - currentGP

        // Persist updated state
        let data: [String: Any] = [
            "practiceId":    "mindfulness",
            "practiceTitle": "Mindfulness",
            "minutes":       newMinutes,
            "gpAwarded":     newGP,
            "dateKey":       today,
            "completedAt":   Timestamp(date: Date())
        ]
        if snap.exists {
            try await docRef.updateData(data)
        } else {
            try await docRef.setData(data)
        }

        // Streak + practice count: on first log of the day, regardless of how many minutes
        // (was previously gated on gpDelta > 0, so sub-5-min sessions were silently dropped)
        if !snap.exists {
            Task {
                let userRef = db.collection("users").document(userId)
                try? await userRef.updateData([
                    "totalPracticeCount": FieldValue.increment(Int64(1))
                ])
                await StreakService.shared.updateStreak(userId: userId)
                let newSnap = try? await userRef.getDocument()
                let newCount = (newSnap?.data()?["totalPracticeCount"] as? Int) ?? 1
                await BadgeService.shared.checkAndAwardPractice(userId: userId, practiceCount: newCount)
            }
        }

        guard gpDelta > 0 else { return 0 }

        // Award GP on user profile
        try await db.collection("users").document(userId).updateData([
            "totalGP": FieldValue.increment(Int64(gpDelta))
        ])

        // Journey event for this milestone
        let subtitle = newGP == 5
            ? "\(newMinutes) min · daily goal reached 🌿"
            : "\(newMinutes) min · keep going"
        let event = JourneyEvent(
            userId: userId,
            type: .dailyPracticeCompleted,
            title: "🧘 Mindfulness",
            subtitle: subtitle,
            gpEarned: gpDelta,
            createdAt: Date(),
            practiceId: "mindfulness",
            responses: nil
        )
        try db.collection("journeyEvents").addDocument(from: event)

        // Background: competency points (only when GP was earned at a new tier)
        Task {
            if let competencyId = (DailyPractice.catalog.first { $0.id == "mindfulness" })?.competencyId {
                try? await CompetencyService.shared.addPoints(
                    userId: userId, competencyId: competencyId, points: gpDelta
                )
            }
        }

        return gpDelta
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

        // Background: competency points + practice count + streak + badge check
        Task {
            // Competency points
            if let competencyId = practice.competencyId {
                try? await CompetencyService.shared.addPoints(
                    userId: userId,
                    competencyId: competencyId,
                    points: practice.gpReward
                )
            }

            // Increment totalPracticeCount and update streak atomically
            let userRef = db.collection("users").document(userId)
            try? await userRef.updateData([
                "totalPracticeCount": FieldValue.increment(Int64(1))
            ])
            await StreakService.shared.updateStreak(userId: userId)

            // Badge check
            let snap = try? await userRef.getDocument()
            let newCount = (snap?.data()?["totalPracticeCount"] as? Int) ?? 1
            await BadgeService.shared.checkAndAwardPractice(userId: userId, practiceCount: newCount)
        }
    }
}
