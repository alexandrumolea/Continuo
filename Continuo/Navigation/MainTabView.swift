import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        Group {
            if auth.profile?.role == .coach {
                coachTabs
            } else {
                clientTabs
            }
        }
        .tint(ContinuoTheme.sunYellow)
    }

    private var clientTabs: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home",    systemImage: "house.fill") }
            CoreView()
                .tabItem { Label("Core",    systemImage: "scope") }
            GrowthView()
                .tabItem { Label("Growth",  systemImage: "star.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
        }
    }

    private var coachTabs: some View {
        TabView {
            CoachClientsView()
                .tabItem { Label("Clients", systemImage: "person.2.fill") }
            GrowthView()
                .tabItem { Label("Growth",  systemImage: "star.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
        }
    }
}

#Preview {
    MainTabView().environmentObject(AuthService())
}
