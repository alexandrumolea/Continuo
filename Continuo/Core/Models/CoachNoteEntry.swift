import Foundation
import FirebaseFirestore

/// A single timestamped note entry a coach keeps about a client.
/// Stored as a subcollection under coachClientNotes/{coachId}_{clientId}/entries.
struct CoachNoteEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var createdAt: Date
}
