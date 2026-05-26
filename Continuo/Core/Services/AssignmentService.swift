import Foundation
import FirebaseFirestore

final class AssignmentService {
    static let shared = AssignmentService()
    private let db = Firestore.firestore()

    // MARK: - Coach: send assignment
    func sendAssignment(_ assignment: Assignment) throws {
        try db.collection("assignments").addDocument(from: assignment)
    }

    // MARK: - Delete assignment
    func deleteAssignment(_ assignment: Assignment) async throws {
        guard let id = assignment.id else { return }
        try await db.collection("assignments").document(id).delete()

        // Deduct competency points earned through completions of this assignment
        if let competencyId = assignment.competencyId, assignment.completionCount > 0 {
            Task {
                try? await CompetencyService.shared.addPoints(
                    userId: assignment.clientId,
                    competencyId: competencyId,
                    points: -(assignment.gpReward * assignment.completionCount)
                )
            }
        }
    }

    // MARK: - Coach: fetch clients (users where coachId == myUid)
    func clientsListener(coachId: String, onChange: @escaping ([ContinuoUser]) -> Void) -> ListenerRegistration {
        db.collection("users")
            .whereField("coachId", isEqualTo: coachId)
            .addSnapshotListener { snapshot, _ in
                Task { @MainActor in
                    let clients = snapshot?.documents.compactMap { try? $0.data(as: ContinuoUser.self) } ?? []
                    onChange(clients)
                }
            }
    }

    // MARK: - Coach: fetch assignments sent by coach
    func coachAssignmentsListener(coachId: String, onChange: @escaping ([Assignment]) -> Void) -> ListenerRegistration {
        db.collection("assignments")
            .whereField("coachId", isEqualTo: coachId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: Assignment.self) } ?? []
                onChange(items)
            }
    }

    // MARK: - Coach: all assignments for a specific client (single-field query, no index needed)
    func assignmentsForClientListener(clientId: String, onChange: @escaping ([Assignment]) -> Void) -> ListenerRegistration {
        db.collection("assignments")
            .whereField("clientId", isEqualTo: clientId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ assignmentsForClientListener: \(error.localizedDescription)")
                }
                let items = snapshot?.documents.compactMap { try? $0.data(as: Assignment.self) } ?? []
                onChange(items.sorted { $0.createdAt > $1.createdAt })
            }
    }

    // MARK: - Coach: extend expiry
    func extendExpiry(assignmentId: String, by days: Int) async throws {
        let newExpiry = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        try await db.collection("assignments").document(assignmentId).updateData([
            "expiresAt": Timestamp(date: newExpiry),
            "status": AssignmentStatus.active.rawValue
        ])
    }

    // MARK: - Coach: find coach by code (first 6 chars of UID)
    func findCoach(byCode code: String, completion: @escaping (ContinuoUser?) -> Void) {
        db.collection("users")
            .whereField("role", isEqualTo: UserRole.coach.rawValue)
            .getDocuments { snapshot, _ in
                Task { @MainActor in
                    let coaches = snapshot?.documents.compactMap { try? $0.data(as: ContinuoUser.self) } ?? []
                    let match = coaches.first { user in
                        (user.id ?? "").prefix(6).uppercased() == code.uppercased()
                    }
                    completion(match)
                }
            }
    }

    // MARK: - Client: connect to coach
    func connectToCoach(clientId: String, coachId: String) async throws {
        try await db.collection("users").document(clientId).updateData(["coachId": coachId])
    }

    // MARK: - Client: fetch active assignments
    func clientAssignmentsListener(clientId: String, onChange: @escaping ([Assignment]) -> Void) -> ListenerRegistration {
        db.collection("assignments")
            .whereField("clientId", isEqualTo: clientId)
            .whereField("status", isEqualTo: AssignmentStatus.active.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ clientAssignmentsListener: \(error.localizedDescription)")
                }
                let items = snapshot?.documents
                    .compactMap { try? $0.data(as: Assignment.self) } ?? []
                onChange(items.sorted { $0.createdAt < $1.createdAt })
            }
    }

    // MARK: - Client: complete an assignment round
    func completeAssignment(_ assignment: Assignment, response: String, userId: String) throws {
        guard let id = assignment.id else { return }
        let batch = db.batch()

        // 1. Update assignment
        let assignRef = db.collection("assignments").document(id)
        batch.updateData([
            "lastCompletedAt": Timestamp(date: Date()),
            "completionCount": FieldValue.increment(Int64(1))
        ], forDocument: assignRef)

        // 2. Save completion record
        let completionRef = db.collection("assignmentCompletions").document()
        let completion = AssignmentCompletion(
            assignmentId: id,
            assignmentTitle: assignment.title,
            clientId: assignment.clientId,
            coachId: assignment.coachId,
            response: response,
            completedAt: Date()
        )
        try batch.setData(from: completion, forDocument: completionRef)

        // 3. Award GP only (no journey event — history lives inside the assignment)
        let userRef = db.collection("users").document(userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(assignment.gpReward))], forDocument: userRef)

        batch.commit()

        // Award competency points if the assignment is linked to one (fire-and-forget)
        if let competencyId = assignment.competencyId {
            Task {
                try? await CompetencyService.shared.addPoints(
                    userId: userId,
                    competencyId: competencyId,
                    points: assignment.gpReward
                )
            }
        }
    }

    // MARK: - Client: reactivate a finished assignment (undo finish)
    func reactivateAssignment(_ assignment: Assignment, userId: String) throws {
        guard let id = assignment.id else { return }
        let batch = db.batch()

        let assignRef = db.collection("assignments").document(id)
        batch.updateData(["status": AssignmentStatus.active.rawValue], forDocument: assignRef)

        // Reverse the 50 GP finish bonus
        let userRef = db.collection("users").document(userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(-50))], forDocument: userRef)

        batch.commit()
    }

    // MARK: - Client: mark assignment as Finished
    func finishAssignment(_ assignment: Assignment, userId: String) throws {
        guard let id = assignment.id else { return }
        let batch = db.batch()

        let assignRef = db.collection("assignments").document(id)
        batch.updateData(["status": AssignmentStatus.finished.rawValue], forDocument: assignRef)

        // Big GP bonus + journey event for finishing
        let bonusGP = 50
        let userRef = db.collection("users").document(userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(bonusGP))], forDocument: userRef)

        let eventRef = db.collection("journeyEvents").document()
        let event = JourneyEvent(
            userId: userId,
            type: .skillLevelUp,
            title: "Challenge complete: \(assignment.title)",
            subtitle: "Marked as finished 🏆 +\(bonusGP) GP",
            gpEarned: bonusGP,
            createdAt: Date()
        )
        try batch.setData(from: event, forDocument: eventRef)
        batch.commit()
    }

    // MARK: - Coach: all completions from a specific client
    func coachClientCompletionsListener(
        clientId: String,
        coachId: String,
        onChange: @escaping ([AssignmentCompletion]) -> Void
    ) -> ListenerRegistration {
        db.collection("assignmentCompletions")
            .whereField("coachId", isEqualTo: coachId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ coachClientCompletions: \(error.localizedDescription)")
                }
                let all = snapshot?.documents
                    .compactMap { try? $0.data(as: AssignmentCompletion.self) } ?? []
                onChange(all.filter { $0.clientId == clientId }
                    .sorted { $0.completedAt > $1.completedAt })
            }
    }

    // MARK: - Coach: like/unlike a completion
    func setLiked(_ completion: AssignmentCompletion, liked: Bool) async throws {
        guard let id = completion.id else { return }
        try await db.collection("assignmentCompletions")
            .document(id).updateData(["isLiked": liked])
    }

    // MARK: - Coach: reply to a completion
    func reply(to completion: AssignmentCompletion, text: String) async throws {
        guard let id = completion.id else { return }
        try await db.collection("assignmentCompletions")
            .document(id).updateData(["coachReply": text])
    }

    // MARK: - Client: reply back to coach (legacy single-field)
    func clientReply(to completion: AssignmentCompletion, text: String) async throws {
        guard let id = completion.id else { return }
        try await db.collection("assignmentCompletions")
            .document(id).updateData(["clientReply": text])
    }

    // MARK: - Edit an existing message in the thread
    func editMessage(completion: AssignmentCompletion, messageId: String, newText: String) async throws {
        guard let id = completion.id else { return }
        let updated = completion.messages.map { msg -> [String: Any] in
            ["id": msg.id,
             "role": msg.role,
             "text": msg.id == messageId ? newText : msg.text,
             "sentAt": msg.sentAt]
        }
        try await db.collection("assignmentCompletions").document(id).updateData(["messages": updated])
    }

    // MARK: - Append a message to the conversation thread (both roles)
    func appendMessage(completionId: String, role: String, text: String) async throws {
        let msg: [String: Any] = [
            "id": UUID().uuidString,
            "role": role,
            "text": text,
            "sentAt": Timestamp(date: Date())
        ]
        try await db.collection("assignmentCompletions")
            .document(completionId)
            .updateData(["messages": FieldValue.arrayUnion([msg])])
    }

    // MARK: - Completions history for an assignment
    func completionsListener(assignmentId: String, onChange: @escaping ([AssignmentCompletion]) -> Void) -> ListenerRegistration {
        db.collection("assignmentCompletions")
            .whereField("assignmentId", isEqualTo: assignmentId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ completionsListener: \(error.localizedDescription)")
                }
                let items = snapshot?.documents
                    .compactMap { try? $0.data(as: AssignmentCompletion.self) } ?? []
                onChange(items.sorted { $0.completedAt > $1.completedAt })
            }
    }

    // MARK: - Finished assignments (for Growth tab)
    func finishedAssignmentsListener(clientId: String, onChange: @escaping ([Assignment]) -> Void) -> ListenerRegistration {
        db.collection("assignments")
            .whereField("clientId", isEqualTo: clientId)
            .whereField("status", isEqualTo: AssignmentStatus.finished.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ finishedAssignmentsListener: \(error.localizedDescription)")
                }
                let items = snapshot?.documents
                    .compactMap { try? $0.data(as: Assignment.self) } ?? []
                onChange(items.sorted { $0.createdAt > $1.createdAt })
            }
    }
}
