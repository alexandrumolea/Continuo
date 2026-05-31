//
//  ContinuoApp.swift
//  Continuo
//
//  Created by Alexandru Molea on 5/23/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        configureNavigationBarAppearance()
        return true
    }

    private func configureNavigationBarAppearance() {
        // Charcoal title color on all navigation bars — works for both
        // large titles (Profile, My Clients, etc.) and inline titles.
        let charcoal = UIColor(red: 45/255, green: 41/255, blue: 38/255, alpha: 1) // #2D2926

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()  // keeps the app background visible
        appearance.largeTitleTextAttributes = [
            .foregroundColor: charcoal,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: charcoal,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        // Back button chevron + text
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: charcoal
        ]

        let bar = UINavigationBar.appearance()
        bar.standardAppearance   = appearance
        bar.scrollEdgeAppearance = appearance   // used when scroll position is at top (large title)
        bar.compactAppearance    = appearance
        bar.tintColor            = charcoal     // back chevron + bar button items
    }
}

@main
struct ContinuoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .onOpenURL { url in
                    // Google Sign-In OAuth redirect
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
