import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email        = ""
    @Published var password     = ""
    @Published var displayName  = ""
    @Published var selectedRole: UserRole = .client
    @Published var isLoginMode  = true

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

    var canSubmit: Bool {
        let emailOK    = email.contains("@")
        let passwordOK = password.count >= 6
        let nameOK     = isLoginMode || !displayName.isEmpty
        return emailOK && passwordOK && nameOK
    }
}
