import Foundation
import FirebaseFirestore

/// Private notes a coach keeps about a specific client.
/// Stored at coachClientNotes/{coachId}_{clientId} — one document per pair.
struct CoachClientNote: Codable {
    var coachId: String
    var clientId: String
    var text: String
    var updatedAt: Date
}
