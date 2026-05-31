import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email        = ""
    @Published var password     = ""
    @Published var displayName  = ""
    @Published var selectedRole: UserRole = .client
    @Published var isLoginMode  = true
    /// Required for sign-up only. GDPR best-practice: explicit consent before account creation.
    @Published var agreedToTerms = false
    /// Flips true when the user taps Sign Up without ticking the consent box —
    /// the row then renders an inline red explanation so they know what to do.
    @Published var showTermsError = false

    func submit(using authService: AuthService) {
        Task {
            if isLoginMode {
                await authService.signIn(email: email, password: password)
            } else {
                await authService.signUp(
                    email: email,
                    password: password,
                    displayName: displayName,
                    role: selectedRole
                )
            }
        }
    }

    /// The button is enabled when the *form* is valid. Consent is checked at tap-time
    /// so we can surface a clear error message instead of silently disabling the button.
    var canSubmit: Bool {
        let emailOK    = email.contains("@")
        let passwordOK = password.count >= 6
        let nameOK     = isLoginMode || !displayName.isEmpty
        return emailOK && passwordOK && nameOK
    }
}
