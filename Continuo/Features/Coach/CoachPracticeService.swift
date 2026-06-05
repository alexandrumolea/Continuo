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
        if let q = entry.questionText        { data["questionText"]        = q }
        if let qs = entry.categoryQuestions  { data["categoryQuestions"]   = qs }
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
                        let id            = d["id"]            as? String,
                        let practiceId    = d["practiceId"]    as? String,
                        let practiceTitle = d["practiceTitle"] as? String,
                        let practiceEmoji = d["practiceEmoji"] as? String,
                        let createdAt     = d["createdAt"]     as? Timestamp
                    else { return nil }
                    return CoachPracticeEntry(
                        id: id,
                        practiceId: practiceId,
                        practiceTitle: practiceTitle,
                        practiceEmoji: practiceEmoji,
                        questionText: d["questionText"]            as? String,
                        categoryQuestions: d["categoryQuestions"]  as? [String],
                        responses: (d["responses"] as? [String: String]) ?? [:],
                        createdAt: createdAt
                    )
                } ?? []
                onChange(entries)
            }
    }

    func delete(entryId: String, coachId: String) {
        entriesRef(coachId: coachId).document(entryId).delete()
    }
}
