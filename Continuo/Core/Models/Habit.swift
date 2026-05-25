import Foundation
import FirebaseFirestore

struct Habit: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var emoji: String
    var streak: Int
    var lastCompleted: Date?
    var gpReward: Int

    var isCompletedToday: Bool {
        guard let last = lastCompleted else { return false }
        return Calendar.current.isDateInToday(last)
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, title, emoji, streak, lastCompleted, gpReward
    }
}
