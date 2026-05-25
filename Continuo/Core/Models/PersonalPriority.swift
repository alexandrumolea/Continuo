import Foundation
import FirebaseFirestore

struct PersonalPriority: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var userId: String
    var text: String
    var order: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, text, order, createdAt
    }
}
