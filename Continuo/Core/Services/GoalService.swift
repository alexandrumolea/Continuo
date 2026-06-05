import Foundation
import FirebaseFirestore

final class GoalService {
    static let shared = GoalService()
    private let db = Firestore.firestore()

    // MARK: - Goals
    func goalsListener(userId: String, onChange: @escaping ([Goal]) -> Void) -> ListenerRegistration {
        db.collection("goals")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ goalsListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: Goal.self) } ?? []
                onChange(items.sorted {
                    if $0.order != $1.order { return $0.order < $1.order }
                    return $0.createdAt < $1.createdAt
                })
            }
    }

    func reorder(goals: [Goal]) async throws {
        let batch = db.batch()
        for (index, goal) in goals.enumerated() {
            guard let id = goal.id else { continue }
            batch.updateData(["order": index],
                             forDocument: db.collection("goals").document(id))
        }
        try await batch.commit()
    }

    func addGoal(_ goal: Goal) throws {
        try db.collection("goals").addDocument(from: goal)
    }

    /// Coach creates a goal directly in the client's goals collection.
    /// The goal is automatically shared with the coach and marked as coach-created.
    func addGoalForClient(_ goal: Goal) throws {
        try db.collection("goals").addDocument(from: goal)
    }

    func updateProgress(_ goal: Goal, progress: Double) async throws {
        guard let id = goal.id else { return }
        try await db.collection("goals").document(id).updateData(["progress": progress])
    }

    func updateGoal(_ goal: Goal, title: String, type: GoalType) async throws {
        guard let id = goal.id else { return }
        try await db.collection("goals").document(id).updateData([
            "title": title,
            "type": type.rawValue
        ])
    }

    func updateSuccessMeasure(_ goal: Goal, text: String) async throws {
        guard let id = goal.id else { return }
        try await db.collection("goals").document(id).updateData(["successMeasure": text])
    }

    func deleteGoal(_ goal: Goal) async throws {
        guard let id = goal.id else { return }
        try await db.collection("goals").document(id).delete()
    }

    func setSharedWithCoach(_ goal: Goal, shared: Bool) async throws {
        guard let id = goal.id else { return }
        try await db.collection("goals").document(id).updateData([
            "sharedWithCoach": shared
        ])
    }

    /// Coach listener — returns only goals the client has explicitly shared.
    func sharedGoalsListener(clientId: String,
                             onChange: @escaping ([Goal]) -> Void) -> ListenerRegistration {
        db.collection("goals")
            .whereField("userId", isEqualTo: clientId)
            .whereField("sharedWithCoach", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ sharedGoalsListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: Goal.self) } ?? []
                onChange(items.sorted {
                    if $0.order != $1.order { return $0.order < $1.order }
                    return $0.createdAt < $1.createdAt
                })
            }
    }

    /// One-shot fetch of reflections for a shared goal (coach read-only).
    func reflectionsOnce(goalId: String) async -> [GoalReflection] {
        let snap = try? await db.collection("goals").document(goalId)
            .collection("reflections")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snap?.documents.compactMap { try? $0.data(as: GoalReflection.self) } ?? []
    }

    // MARK: - Reflections (subcollection under goals/{id}/reflections)
    func reflectionsListener(goalId: String, onChange: @escaping ([GoalReflection]) -> Void) -> ListenerRegistration {
        db.collection("goals").document(goalId)
            .collection("reflections")
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ reflectionsListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: GoalReflection.self) } ?? []
                onChange(items.sorted { $0.createdAt > $1.createdAt })
            }
    }

    // Awards 5 GP atomically
    func addReflection(_ reflection: GoalReflection, goalId: String) throws {
        let batch = db.batch()
        let refRef = db.collection("goals").document(goalId)
            .collection("reflections").document()
        try batch.setData(from: reflection, forDocument: refRef)
        let userRef = db.collection("users").document(reflection.userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(5))], forDocument: userRef)
        batch.commit()
    }

    func updateReflection(_ reflection: GoalReflection, goalId: String, text: String) async throws {
        guard let id = reflection.id else { return }
        try await db.collection("goals").document(goalId)
            .collection("reflections").document(id).updateData(["text": text])
    }

    func deleteReflection(_ reflection: GoalReflection, goalId: String) async throws {
        guard let id = reflection.id else { return }
        try await db.collection("goals").document(goalId)
            .collection("reflections").document(id).delete()
    }
}
