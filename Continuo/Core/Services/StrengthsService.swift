import Foundation
import FirebaseFirestore

final class StrengthsService {
    static let shared = StrengthsService()
    private let db = Firestore.firestore()

    func strengthsListener(userId: String, onChange: @escaping ([PersonalStrength]) -> Void) -> ListenerRegistration {
        db.collection("personalStrengths")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ strengthsListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: PersonalStrength.self) } ?? []
                onChange(items.sorted { $0.createdAt < $1.createdAt })
            }
    }

    func addStrength(_ strength: PersonalStrength) throws {
        try db.collection("personalStrengths").addDocument(from: strength)
    }

    func deleteStrength(_ strength: PersonalStrength) async throws {
        guard let id = strength.id else { return }
        try await db.collection("personalStrengths").document(id).delete()
    }
}
