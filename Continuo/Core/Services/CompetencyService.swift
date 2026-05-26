import Foundation
import FirebaseFirestore

final class CompetencyService {
    static let shared = CompetencyService()
    private let db = Firestore.firestore()

    // MARK: - Real-time listener

    func scoresListener(userId: String, onChange: @escaping ([CompetencyScore]) -> Void) -> ListenerRegistration {
        db.collection("competencyScores")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ scoresListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: CompetencyScore.self) } ?? []
                onChange(items)
            }
    }

    // MARK: - Award points
    // Reads the current score, applies daily decay, adds new points, writes back.
    // Document ID is deterministic: "{userId}_{competencyId}"
    func addPoints(userId: String, competencyId: String, points: Int) async throws {
        let docId = "\(userId)_\(competencyId)"
        let ref = db.collection("competencyScores").document(docId)

        let snap = try await ref.getDocument()
        let currentEffective: Int
        if snap.exists, let existing = try? snap.data(as: CompetencyScore.self) {
            currentEffective = existing.effectivePoints   // decay already applied
        } else {
            currentEffective = 0
        }

        try await ref.setData([
            "userId":           userId,
            "competencyId":     competencyId,
            "points":           max(0, currentEffective + points),
            "lastActivityDate": Timestamp(date: Date())
        ])
    }
}
