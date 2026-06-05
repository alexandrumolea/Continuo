import UIKit
import Combine
import UserNotifications
import FirebaseMessaging

// MARK: - NotificationDelegate
// Handles both UNUserNotificationCenter events and FCM token refresh.

final class NotificationDelegate: NSObject {
    static let shared = NotificationDelegate()

    // Publish deep-link targets so SwiftUI views can react.
    // Key: PushNotificationType.rawValue  Value: target document ID (if any)
    @Published var pendingNavigation: (type: String, targetId: String?)? = nil
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationDelegate: UNUserNotificationCenterDelegate {

    /// Called when a notification arrives while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banner + sound even in foreground so the user sees activity updates.
        return [.banner, .sound, .badge]
    }

    /// Called when the user taps a notification or its action button.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        handle(userInfo: userInfo)
        NotificationManager.shared.clearBadge()
    }

    // MARK: - Routing

    private func handle(userInfo: [AnyHashable: Any]) {
        guard let typeRaw = userInfo["type"] as? String else { return }
        let targetId = userInfo["targetId"] as? String
        pendingNavigation = (type: typeRaw, targetId: targetId)
    }
}

// MARK: - MessagingDelegate (FCM token refresh)

extension NotificationDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        // Token refresh — re-save to Firestore if we have a signed-in user.
        NotificationCenter.default.post(
            name: .fcmTokenRefreshed,
            object: nil,
            userInfo: ["token": token]
        )
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let fcmTokenRefreshed = Notification.Name("com.continuo.fcmTokenRefreshed")
}
