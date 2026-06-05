import Foundation
import FirebaseFirestore

enum UserRole: String, Codable, CaseIterable {
    case client = "client"
    case coach  = "coach"

    var displayName: String {
        switch self {
        case .client: return "Client"
        case .coach:  return "Coach"
        }
    }
    var icon: String {
        switch self {
        case .client: return "person.fill"
        case .coach:  return "person.2.fill"
        }
    }
}

struct ContinuoUser: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var role: UserRole
    var coachId: String?
    var totalGP: Int
    /// `false` for social-auth users until they finish the welcome flow (pick name + role).
    /// `nil` for legacy profiles created before this field existed — treated as "complete".
    var setupCompleted: Bool? = nil

    // MARK: - Push Notifications
    /// FCM device token — updated on every app launch.
    var fcmToken: String? = nil

    // MARK: - Streak
    var currentStreak: Int?
    var longestStreak: Int?
    var lastActivityDate: String?  // "yyyy-MM-dd"

    // MARK: - Activity counters (for badge progress)
    var totalPracticeCount: Int?
    var totalCoachingCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, displayName, email, role, coachId, totalGP, setupCompleted
        case currentStreak, longestStreak, lastActivityDate
        case totalPracticeCount, totalCoachingCount
        case fcmToken
    }
}
