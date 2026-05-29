import Foundation
import FirebaseFirestore

/// Best-effort deletion of *all* documents a user owns across the database.
/// Errors on individual docs are logged but never abort the wipe — the goal
/// is to leave as little orphaned data as possible.
final class AccountDeletionService {
    static let shared = AccountDeletionService()
    private let db = Firestore.firestore()

    func wipeAllUserData(uid: String) async {
        // 1. Coach client notes FIRST — they need assignments + user profile to be
        //    present so we can reconstruct pair document IDs (`{coachId}_{clientId}`).
        await deleteCoachClientNotes(for: uid)

        // 2. Simple user-owned collections (single `userId` field).
        let userIdCollections = [
            "journeyEvents",
            "habits", "objectives", "skills",
            "competencyScores",
            "personalPriorities", "personalValues",
            "personalSkills", "personalPassions", "personalStrengths"
        ]
        for name in userIdCollections {
            await deleteByField(collection: name, field: "userId", value: uid)
        }

        // 3. Goals + their `reflections` subcollection.
        let goalsSnap = try? await db.collection("goals")
            .whereField("userId", isEqualTo: uid).getDocuments()
        for doc in goalsSnap?.documents ?? [] {
            await deleteSubcollection(of: doc.reference, name: "reflections")
            try? await doc.reference.delete()
        }

        // 4. Coaching sessions (user side AND coach side).
        await deleteByField(collection: "coachingSessions", field: "userId", value: uid)
        await deleteByField(collection: "coachingSessions", field: "coachId", value: uid)

        // 5. Assignments (client or coach).
        await deleteByField(collection: "assignments", field: "clientId", value: uid)
        await deleteByField(collection: "assignments", field: "coachId", value: uid)

        // 6. Assignment completions.
        await deleteByField(collection: "assignmentCompletions", field: "clientId", value: uid)
        await deleteByField(collection: "assignmentCompletions", field: "coachId", value: uid)

        // 7. User subcollection — dailyCompletions.
        let userRef = db.collection("users").document(uid)
        await deleteSubcollection(of: userRef, name: "dailyCompletions")

        // 8. Finally, the user profile doc itself.
        try? await userRef.delete()
    }

    // MARK: - Helpers

    private func deleteByField(collection name: String, field: String, value: String) async {
        let snap = try? await db.collection(name)
            .whereField(field, isEqualTo: value).getDocuments()
        for doc in snap?.documents ?? [] {
            try? await doc.reference.delete()
        }
    }

    private func deleteSubcollection(of ref: DocumentReference, name: String) async {
        let snap = try? await ref.collection(name).getDocuments()
        for doc in snap?.documents ?? [] {
            try? await doc.reference.delete()
        }
    }

    /// Coach client notes use composite document IDs `{coachId}_{clientId}` so we
    /// can't query by prefix — we reconstruct them from the user's relationships.
    private func deleteCoachClientNotes(for uid: String) async {
        var pairIds: Set<String> = []

        // As a coach: find every client we have an assignment with.
        if let snap = try? await db.collection("assignments")
            .whereField("coachId", isEqualTo: uid).getDocuments() {
            for doc in snap.documents {
                if let clientId = doc.data()["clientId"] as? String {
                    pairIds.insert("\(uid)_\(clientId)")
                }
            }
        }

        // As a client: read our coachId from the user profile.
        if let userSnap = try? await db.collection("users").document(uid).getDocument(),
           let coachId = userSnap.data()?["coachId"] as? String, !coachId.isEmpty {
            pairIds.insert("\(coachId)_\(uid)")
        }

        for pairId in pairIds {
            let docRef = db.collection("coachClientNotes").document(pairId)
            await deleteSubcollection(of: docRef, name: "entries")
            try? await docRef.delete()
        }
    }
}
