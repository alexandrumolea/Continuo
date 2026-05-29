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
    }
}

#Preview {
    RootView().environmentObject(AuthService())
}
