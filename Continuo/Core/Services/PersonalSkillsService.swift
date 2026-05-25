import Foundation
import FirebaseFirestore

final class PersonalSkillsService {
    static let shared = PersonalSkillsService()
    private let db = Firestore.firestore()

    func skillsListener(userId: String, onChange: @escaping ([PersonalSkill]) -> Void) -> ListenerRegistration {
        db.collection("personalSkills")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ skillsListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: PersonalSkill.self) } ?? []
                onChange(items.sorted { $0.createdAt < $1.createdAt })
            }
    }

    func addSkill(_ skill: PersonalSkill) throws {
        try db.collection("personalSkills").addDocument(from: skill)
    }

    func deleteSkill(_ skill: PersonalSkill) async throws {
        guard let id = skill.id else { return }
        try await db.collection("personalSkills").document(id).delete()
    }
}
