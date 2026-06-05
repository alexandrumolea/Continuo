import Foundation
import FirebaseFirestore

final class CoachPracticeService {
    static let shared = CoachPracticeService()
    private let db = Firestore.firestore()

    private func entriesRef(coachId: String) -> CollectionReference {
        db.collection("coachPractice").document(coachId).collection("entries")
    }

    func save(entry: CoachPracticeEntry, coachId: String) {
        var data: [String: Any] = [
            "id": entry.id,
            "practiceId": entry.practiceId,
            "practiceTitle": entry.practiceTitle,
            "practiceEmoji": entry.practiceEmoji,
            "responses": entry.responses,
            "createdAt": entry.createdAt
        ]
        if let q = entry.questionText { data["questionText"] = q }
        entriesRef(coachId: coachId).document(entry.id).setData(data)
    }

    func recentEntriesListener(
        coachId: String,
        limit: Int = 30,
        onChange: @escaping ([CoachPracticeEntry]) -> Void
    ) -> ListenerRegistration {
        entriesRef(coachId: coachId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ CoachPracticeService listener: \(error.localizedDescription)")
                    return
                }
                let entries: [CoachPracticeEntry] = snapshot?.documents.compactMap { doc in
                    let d = doc.data()
                    guard
                        let id = d["id"] as? String,
                        let practiceId = d["practiceId"] as? String,
                        let practiceTitle = d["practiceTitle"] as? String,
                        let practiceEmoji = d["practiceEmoji"] as? String,
                        let responses = d["responses"] as? [String: String],
                        let createdAt = d["createdAt"] as? Timestamp
                    else { return nil }
                    return CoachPracticeEntry(
                        id: id,
                        practiceId: practiceId,
                        practiceTitle: practiceTitle,
                        practiceEmoji: practiceEmoji,
                        questionText: d["questionText"] as? String,
                        responses: responses,
                        createdAt: createdAt
                    )
                } ?? []
                onChange(entries)
            }
    }

    // Returns all question texts that have been reflected on for a given practice
    func delete(entryId: String, coachId: String) {
        entriesRef(coachId: coachId).document(entryId).delete()
    }

    func completedQuestionsListener(
        coachId: String,
        practiceId: String,
        onChange: @escaping (Set<String>) -> Void
    ) -> ListenerRegistration {
        entriesRef(coachId: coachId)
            .whereField("practiceId", isEqualTo: practiceId)
            .addSnapshotListener { snapshot, _ in
                let questions = Set(
                    snapshot?.documents.compactMap { $0.data()["questionText"] as? String } ?? []
                )
                onChange(questions)
            }
    }
}
