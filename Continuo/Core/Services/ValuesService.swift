import Foundation
import FirebaseFirestore

final class ValuesService {
    static let shared = ValuesService()
    private let db = Firestore.firestore()

    func valuesListener(userId: String, onChange: @escaping ([PersonalValue]) -> Void) -> ListenerRegistration {
        db.collection("personalValues")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ valuesListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: PersonalValue.self) } ?? []
                onChange(items.sorted { $0.createdAt < $1.createdAt })
            }
    }

    func addValue(_ value: PersonalValue) throws {
        try db.collection("personalValues").addDocument(from: value)
    }

    func deleteValue(_ value: PersonalValue) async throws {
        guard let id = value.id else { return }
        try await db.collection("personalValues").document(id).delete()
    }
}
