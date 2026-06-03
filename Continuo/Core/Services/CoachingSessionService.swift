import Foundation
import FirebaseFirestore

final class CoachingSessionService {
    static let shared = CoachingSessionService()
    private let db = Firestore.firestore()
    private let gpReward = 30

    // MARK: - Real-time listener

    func sessionsListener(userId: String,
                          onChange: @escaping ([CoachingSession]) -> Void) -> ListenerRegistration {
        db.collection("coachingSessions")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error { print("❌ sessionsListener: \(error.localizedDescription)") }
                let items = snapshot?.documents.compactMap { try? $0.data(as: CoachingSession.self) } ?? []
                onChange(items.sorted { $0.sessionDate > $1.sessionDate })
            }
    }

    // MARK: - Client logs own session

    func logSession(userId: String, sessionDate: Date,
                    summary: String, conclusions: String, actions: String) throws {
        let batch = db.batch()

        let session = CoachingSession(
            userId: userId, coachId: nil,
            sessionDate: sessionDate,
            summary: summary.isEmpty ? nil : summary,
            conclusions: conclusions, actions: actions,
            gpEarned: gpReward, createdAt: Date()
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
        incrementAndCheckCoaching(userId: userId)
    }

    // MARK: - Coach logs session for a client

    func logSessionByCoach(clientId: String, coachId: String,
                           sessionDate: Date, summary: String,
                           conclusions: String, actions: String) throws {
        let batch = db.batch()

        let session = CoachingSession(
            userId: clientId, coachId: coachId,
            sessionDate: sessionDate,
            summary: summary.isEmpty ? nil : summary,
            conclusions: conclusions, actions: actions,
            gpEarned: gpReward, createdAt: Date()
        )
        let sessionRef = db.collection("coachingSessions").document()
        try batch.setData(from: session, forDocument: sessionRef)

        let userRef = db.collection("users").document(clientId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(gpReward))], forDocument: userRef)

        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        let event = JourneyEvent(
            userId: clientId, type: .sessionLogged,
            title: "🤝 Coaching Session", subtitle: f.string(from: sessionDate),
            gpEarned: gpReward, createdAt: Date()
        )
        let eventRef = db.collection("journeyEvents").document()
        try batch.setData(from: event, forDocument: eventRef)

        batch.commit()
        incrementAndCheckCoaching(userId: clientId)
    }

    // MARK: - Update (client edits their own OR a coach-logged session)

    func updateSession(_ session: CoachingSession, date: Date,
                       summary: String, conclusions: String, actions: String) async throws {
        guard let id = session.id else { return }
        var data: [String: Any] = [
            "sessionDate": Timestamp(date: date),
            "conclusions": conclusions,
            "actions":     actions
        ]
        if !summary.isEmpty { data["summary"] = summary }
        try await db.collection("coachingSessions").document(id).updateData(data)
    }

    // MARK: - Private helpers

    private func incrementAndCheckCoaching(userId: String) {
        Task {
            let userRef = db.collection("users").document(userId)
            try? await userRef.updateData([
                "totalCoachingCount": FieldValue.increment(Int64(1))
            ])
            await StreakService.shared.updateStreak(userId: userId)
            let snap = try? await userRef.getDocument()
            let newCount = (snap?.data()?["totalCoachingCount"] as? Int) ?? 1
            await BadgeService.shared.checkAndAwardCoaching(userId: userId, coachingCount: newCount)
        }
    }

    // MARK: - Delete session + deduct GP

    func deleteSession(_ session: CoachingSession) async throws {
        guard let id = session.id else { return }
        let batch = db.batch()
        batch.deleteDocument(db.collection("coachingSessions").document(id))
        let userRef = db.collection("users").document(session.userId)
        batch.updateData(["totalGP": FieldValue.increment(Int64(-session.gpEarned))], forDocument: userRef)
        try await batch.commit()
    }
}
