import Foundation
import FirebaseFirestore

final class CoachingSessionService {
    static let shared = CoachingSessionService()
    private let db = Firestore.firestore()

    private let gpReward = 30

    // Real-time listener — newest sessions first
    func sessionsListener(userId: String, onChange: @escaping ([CoachingSession]) -> Void) -> ListenerRegistration {
        db.collection("coachingSessions")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ sessionsListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: CoachingSession.self) } ?? []
                onChange(items.sorted { $0.sessionDate > $1.sessionDate })
            }
    }

    // Batch: save session + award GP + create journey event
    func logSession(userId: String, sessionDate: Date, conclusions: String, actions: String) throws {
        let batch = db.batch()

        let session = CoachingSession(
            userId: userId,
            sessionDate: sessionDate,
            conclusions: conclusions,
            actions: actions,
            gpEarned: gpReward,
            createdAt: Date()
        )
        let sessionRef = db.collection("coachingSessions").document()
        try batch.setData(from: session, forDocument: sessionRef)

        let userRef = db.collection("users").document(userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(gpReward))], forDocument: userRef)

        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        let event = JourneyEvent(
            userId: userId, type: .sessionLogged,
            title: "🤝 Coaching Session", subtitle: f.string(from: sessionDate),
            gpEarned: gpReward, createdAt: Date()
        )
        let eventRef = db.collection("journeyEvents").document()
        try batch.setData(from: event, forDocument: eventRef)

        batch.commit()
    }

    // Edit session notes/date — no GP change
    func updateSession(_ session: CoachingSession, date: Date, conclusions: String, actions: String) async throws {
        guard let id = session.id else { return }
        try await db.collection("coachingSessions").document(id).updateData([
            "sessionDate": Timestamp(date: date),
            "conclusions": conclusions,
            "actions":     actions
        ])
    }

    // Delete session AND deduct its GP from the user's total
    func deleteSession(_ session: CoachingSession) async throws {
        guard let id = session.id else { return }
        let batch = db.batch()
        batch.deleteDocument(db.collection("coachingSessions").document(id))
        let userRef = db.collection("users").document(session.userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(-session.gpEarned))], forDocument: userRef)
        try await batch.commit()
    }
}
