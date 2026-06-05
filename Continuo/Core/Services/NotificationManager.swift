import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

// MARK: - Notification type constants (mirrored in Cloud Functions)

enum PushNotificationType: String {
    // Coach → Client
    case assignmentReceived     = "assignment_received"
    case goalReceived           = "goal_received"
    case feedbackFormReceived   = "feedback_form_received"
    case coachReplied           = "coach_replied"
    case sessionLoggedByCoach   = "session_logged_by_coach"

    // Client → Coach
    case assignmentCompleted    = "assignment_completed"
    case clientReplied          = "client_replied"
    case feedbackSubmitted      = "feedback_submitted"
    case sessionLoggedByClient  = "session_logged_by_client"
}

// MARK: - NotificationManager

@MainActor
final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    private let db = Firestore.firestore()

    // MARK: - Authorization + Registration

    /// Call once at an appropriate moment (e.g. after onboarding).
    func requestAuthorizationAndRegister() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        // Only show the system prompt if not yet determined.
        guard settings.authorizationStatus == .notDetermined else {
            if settings.authorizationStatus == .authorized ||
               settings.authorizationStatus == .provisional {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("❌ NotificationManager: authorization error — \(error.localizedDescription)")
        }
    }

    // MARK: - FCM Token → Firestore

    /// Persist the FCM token on the user document so Cloud Functions can address this device.
    func saveFCMToken(_ token: String, userId: String) {
        db.collection("users").document(userId).updateData(["fcmToken": token]) { error in
            if let error {
                print("❌ NotificationManager: failed to save FCM token — \(error.localizedDescription)")
            }
        }
    }

    /// Refresh & persist token for the current signed-in user.
    func refreshToken(userId: String) {
        Messaging.messaging().token { token, error in
            if let error {
                print("❌ NotificationManager: FCM token fetch error — \(error.localizedDescription)")
                return
            }
            if let token {
                Task { @MainActor in
                    NotificationManager.shared.saveFCMToken(token, userId: userId)
                }
            }
        }
    }

    // MARK: - Badge

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
