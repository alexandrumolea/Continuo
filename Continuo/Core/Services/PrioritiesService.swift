import Foundation
import FirebaseFirestore

final class PrioritiesService {
    static let shared = PrioritiesService()
    private let db = Firestore.firestore()

    func prioritiesListener(userId: String, onChange: @escaping ([PersonalPriority]) -> Void) -> ListenerRegistration {
        db.collection("personalPriorities")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ prioritiesListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: PersonalPriority.self) } ?? []
                onChange(items.sorted { $0.order < $1.order })
            }
    }

    func addPriority(_ priority: PersonalPriority) throws {
        try db.collection("personalPriorities").addDocument(from: priority)
    }

    func deletePriority(_ priority: PersonalPriority) async throws {
        guard let id = priority.id else { return }
        try await db.collection("personalPriorities").document(id).delete()
    }

    /// Writes each item's order as its array index — call after any move or delete.
    func reorder(priorities: [PersonalPriority]) async throws {
        let batch = db.batch()
        for (index, priority) in priorities.enumerated() {
            guard let id = priority.id else { continue }
            let ref = db.collection("personalPriorities").document(id)
            batch.updateData(["order": index], forDocument: ref)
        }
        try await batch.commit()
    }
}
