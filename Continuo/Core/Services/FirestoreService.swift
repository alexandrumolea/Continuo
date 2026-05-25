import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    // MARK: - Habits

    func habitsListener(userId: String, onChange: @escaping ([Habit]) -> Void) -> ListenerRegistration {
        db.collection("habits")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: Habit.self) } ?? []
                onChange(items)
            }
    }

    func addHabit(_ habit: Habit) throws {
        try db.collection("habits").addDocument(from: habit)
    }

    func completeHabit(_ habit: Habit) async throws {
        guard let id = habit.id else { return }
        let newStreak = habit.isCompletedToday ? habit.streak : habit.streak + 1
        try await db.collection("habits").document(id).updateData([
            "lastCompleted": Timestamp(date: Date()),
            "streak": newStreak
        ])
    }

    func deleteHabit(_ habit: Habit) async throws {
        guard let id = habit.id else { return }
        try await db.collection("habits").document(id).delete()
    }

    // MARK: - Objectives

    func objectivesListener(userId: String, onChange: @escaping ([Objective]) -> Void) -> ListenerRegistration {
        db.collection("objectives")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: Objective.self) } ?? []
                onChange(items)
            }
    }

    func addObjective(_ objective: Objective) throws {
        try db.collection("objectives").addDocument(from: objective)
    }

    func updateObjectiveProgress(_ objective: Objective, progress: Double) async throws {
        guard let id = objective.id else { return }
        try await db.collection("objectives").document(id).updateData(["progress": progress])
    }

    func deleteObjective(_ objective: Objective) async throws {
        guard let id = objective.id else { return }
        try await db.collection("objectives").document(id).delete()
    }

    // MARK: - Skills

    func skillsListener(userId: String, onChange: @escaping ([Skill]) -> Void) -> ListenerRegistration {
        db.collection("skills")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: Skill.self) } ?? []
                onChange(items)
            }
    }

    func addSkill(_ skill: Skill) throws {
        try db.collection("skills").addDocument(from: skill)
    }

    func updateSkillProgress(_ skill: Skill, progress: Double) async throws {
        guard let id = skill.id else { return }
        try await db.collection("skills").document(id).updateData(["progress": progress])
    }

    // MARK: - Journey Events

    func journeyListener(userId: String, onChange: @escaping ([JourneyEvent]) -> Void) -> ListenerRegistration {
        db.collection("journeyEvents")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ journeyListener: \(error.localizedDescription)")
                }
                let items = snapshot?.documents.compactMap { try? $0.data(as: JourneyEvent.self) } ?? []
                onChange(items.sorted { $0.createdAt > $1.createdAt })
            }
    }

    func addJourneyEvent(_ event: JourneyEvent) throws {
        try db.collection("journeyEvents").addDocument(from: event)
    }

    func deleteJourneyEvent(_ event: JourneyEvent) async throws {
        guard let id = event.id else { return }
        try await db.collection("journeyEvents").document(id).delete()
    }

    // MARK: - GP

    func incrementGP(userId: String, amount: Int) async throws {
        try await db.collection("users").document(userId).updateData([
            "totalGP": FieldValue.increment(Int64(amount))
        ])
    }

    // MARK: - Composite: award GP + log journey event atomically-ish
    func awardGP(userId: String, amount: Int, event: JourneyEvent) throws {
        let batch = db.batch()
        let userRef = db.collection("users").document(userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(amount))], forDocument: userRef)
        let eventRef = db.collection("journeyEvents").document()
        try batch.setData(from: event, forDocument: eventRef)
        batch.commit()
    }
}
