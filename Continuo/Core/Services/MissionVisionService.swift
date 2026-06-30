import Foundation
import FirebaseFirestore

final class MissionVisionService {
    static let shared = MissionVisionService()
    private let db = Firestore.firestore()

    // Single document per user: missionVision/{userId}
    private func docRef(userId: String) -> DocumentReference {
        db.collection("missionVision").document(userId)
    }

    func listener(userId: String, onChange: @escaping (MissionVision?) -> Void) -> ListenerRegistration {
        docRef(userId: userId).addSnapshotListener { snapshot, error in
            if let error = error { print("❌ missionVisionListener: \(error.localizedDescription)") }
            let item = try? snapshot?.data(as: MissionVision.self)
            onChange(item)
        }
    }

    func save(userId: String, mission: String, vision: String) throws {
        let mv = MissionVision(
            userId: userId,
            mission: mission,
            vision: vision,
            updatedAt: Date()
        )
        try docRef(userId: userId).setData(from: mv, merge: true)
    }
}
