import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        Group {
            if auth.isSignedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                AuthView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isSignedIn)
        // Welcome setup — required for any social-auth profile that still has the "User" placeholder.
        .fullScreenCover(isPresented: Binding(
            get: { auth.isSignedIn && auth.needsProfileSetup },
            set: { _ in }
        )) {
            WelcomeSetupView()
        }
        // Push notifications — request permission + sync FCM token when a user signs in.
        .onChange(of: auth.profile?.id) { _, userId in
            guard let userId else { return }
            Task {
                await NotificationManager.shared.requestAuthorizationAndRegister()
                NotificationManager.shared.refreshToken(userId: userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fcmTokenRefreshed)) { notification in
            guard
                let token = notification.userInfo?["token"] as? String,
                let userId = auth.profile?.id
            else { return }
            NotificationManager.shared.saveFCMToken(token, userId: userId)
        }
    }
}

#Preview {
    RootView().environmentObject(AuthService())
}
