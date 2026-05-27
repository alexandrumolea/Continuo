import Foundation
import FirebaseFirestore

final class CoachClientNoteService {
    static let shared = CoachClientNoteService()
    private let db = Firestore.firestore()

    // MARK: - Subcollection reference

    private func entriesRef(coachId: String, clientId: String) -> CollectionReference {
        db.collection("coachClientNotes")
          .document("\(coachId)_\(clientId)")
          .collection("entries")
    }

    // MARK: - Timeline entries (new)

    func entriesListener(coachId: String, clientId: String,
                         onChange: @escaping ([CoachNoteEntry]) -> Void) -> ListenerRegistration {
        entriesRef(coachId: coachId, clientId: clientId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snap, _ in
                let items = snap?.documents.compactMap { try? $0.data(as: CoachNoteEntry.self) } ?? []
                onChange(items)
            }
    }

    func addEntry(coachId: String, clientId: String, text: String) async throws {
        let entry = CoachNoteEntry(text: text, createdAt: Date())
        try entriesRef(coachId: coachId, clientId: clientId).addDocument(from: entry)
    }

    func deleteEntry(coachId: String, clientId: String, entry: CoachNoteEntry) async throws {
        guard let id = entry.id else { return }
        try await entriesRef(coachId: coachId, clientId: clientId).document(id).delete()
    }

    func hasEntries(coachId: String, clientId: String) async -> Bool {
        let snap = try? await entriesRef(coachId: coachId, clientId: clientId)
            .limit(to: 1).getDocuments()
        return !(snap?.documents.isEmpty ?? true)
    }

    // MARK: - Legacy (single-document notes — kept for backward compat)

    private func legacyDocRef(coachId: String, clientId: String) -> DocumentReference {
        db.collection("coachClientNotes").document("\(coachId)_\(clientId)")
    }

    func fetchNote(coachId: String, clientId: String) async -> CoachClientNote? {
        let snap = try? await legacyDocRef(coachId: coachId, clientId: clientId).getDocument()
        return try? snap?.data(as: CoachClientNote.self)
    }
}
