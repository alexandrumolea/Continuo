import Foundation
import FirebaseFirestore

final class PersonalPassionsService {
    static let shared = PersonalPassionsService()
    private let db = Firestore.firestore()

    func passionsListener(userId: String, onChange: @escaping ([PersonalPassion]) -> Void) -> ListenerRegistration {
        db.collection("personalPassions")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ passionsListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: PersonalPassion.self) } ?? []
                onChange(items.sorted { $0.createdAt < $1.createdAt })
            }
    }

    func addPassion(_ passion: PersonalPassion) throws {
        try db.collection("personalPassions").addDocument(from: passion)
    }

    func deletePassion(_ passion: PersonalPassion) async throws {
        guard let id = passion.id else { return }
        try await db.collection("personalPassions").document(id).delete()
    }
}
