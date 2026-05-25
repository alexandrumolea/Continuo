import Foundation
import FirebaseFirestore

struct PersonalValue: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var userId: String
    var text: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, text, createdAt
    }
}
