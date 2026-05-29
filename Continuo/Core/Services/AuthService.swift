import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FacebookLogin
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthService: ObservableObject {
    @Published var firebaseUser: User?
    @Published var profile: ContinuoUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// True when the signed-in profile still has the social-auth placeholder name ("User" or empty),
    /// signaling that we should present the welcome setup sheet so the user can pick name + role.
    @Published var needsProfileSetup: Bool = false

    private let db = Firestore.firestore()
    private var profileListener: ListenerRegistration?
    private var authHandle: AuthStateDidChangeListenerHandle?
    /// Raw nonce kept between the Apple request and the Firebase credential exchange.
    private var currentAppleNonce: String?

    init() {
        // Restore session synchronously
        firebaseUser = Auth.auth().currentUser
        if let uid = firebaseUser?.uid {
            attachProfileListener(uid: uid)
        }

        // React to future auth changes
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.firebaseUser = user
                if let uid = user?.uid {
                    self?.attachProfileListener(uid: uid)
                } else {
                    self?.profileListener?.remove()
                    self?.profile = nil
                }
            }
        }
    }

    var isSignedIn: Bool { firebaseUser != nil }

    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError {
            errorMessage = authErrorMessage(from: error)
            print("❌ SignIn error: \(error.code) — \(error.localizedDescription)\n\(error.userInfo)")
        }
        isLoading = false
    }

    // MARK: - Password reset (email magic link)
    /// Sends a Firebase password-reset email. Throws on invalid email / network errors.
    func sendPasswordReset(email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "PasswordReset", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Please enter your email first."])
        }
        try await Auth.auth().sendPasswordReset(withEmail: trimmed)
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, displayName: String, role: UserRole) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            let newUser = ContinuoUser(
                displayName: displayName,
                email: email,
                role: role,
                coachId: nil,
                totalGP: 0
            )
            try db.collection("users").document(uid).setData(from: newUser)
        } catch let error as NSError {
            errorMessage = authErrorMessage(from: error)
            print("❌ SignUp error: \(error.code) — \(error.localizedDescription)\n\(error.userInfo)")
        }
        isLoading = false
    }

    // MARK: - Human-readable Firebase errors
    private func authErrorMessage(from error: NSError) -> String {
        switch AuthErrorCode(rawValue: error.code) {
        case .emailAlreadyInUse:    return "This email is already registered."
        case .invalidEmail:         return "Please enter a valid email address."
        case .weakPassword:         return "Password must be at least 6 characters."
        case .wrongPassword:        return "Incorrect password. Please try again."
        case .userNotFound:         return "No account found with this email."
        case .networkError:         return "Network error. Check your connection."
        case .operationNotAllowed:  return "Email sign-in is not enabled. Enable it in Firebase Console → Authentication → Sign-in method."
        default:                    return error.localizedDescription
        }
    }

    // MARK: - Facebook Sign In
    func signInWithFacebook() async {
        isLoading = true
        errorMessage = nil

        do {
            let token = try await facebookAccessToken()
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            let result = try await Auth.auth().signIn(with: credential)
            let uid = result.user.uid

            // Create profile if new user
            let doc = try await db.collection("users").document(uid).getDocument()
            if !doc.exists {
                let name = result.user.displayName ?? "User"
                let email = result.user.email ?? ""
                let newUser = ContinuoUser(displayName: name, email: email, role: .client, coachId: nil, totalGP: 0)
                try db.collection("users").document(uid).setData(from: newUser)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Facebook SignIn error: \(error)")
        }
        isLoading = false
    }

    private func facebookAccessToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let manager = LoginManager()
            manager.logIn(permissions: ["email", "public_profile"], from: nil) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result, !result.isCancelled,
                      let token = result.token?.tokenString else {
                    continuation.resume(throwing: NSError(
                        domain: "FacebookAuth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Facebook login cancelled"]
                    ))
                    return
                }
                continuation.resume(returning: token)
            }
        }
    }

    // MARK: - Apple Sign In

    /// Prepares an Apple Sign In request: stores a fresh nonce and sets the hashed nonce on the request.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    /// Handles the completion of `SignInWithAppleButton`. Exchanges the Apple credential for a Firebase session.
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw NSError(domain: "AppleAuth", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential."])
            }
            guard let nonce = currentAppleNonce else {
                throw NSError(domain: "AppleAuth", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Missing Apple nonce. Try again."])
            }
            guard let identityTokenData = credential.identityToken,
                  let idTokenString = String(data: identityTokenData, encoding: .utf8) else {
                throw NSError(domain: "AppleAuth", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Unable to fetch Apple identity token."])
            }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: credential.fullName
            )
            let result = try await Auth.auth().signIn(with: firebaseCredential)
            let uid = result.user.uid

            // Create profile on first sign in only (Apple gives name/email exactly once).
            let doc = try await db.collection("users").document(uid).getDocument()
            if !doc.exists {
                let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                let displayName = !nameParts.isEmpty
                    ? nameParts
                    : (result.user.displayName ?? "User")
                let email = credential.email ?? result.user.email ?? ""
                let newUser = ContinuoUser(displayName: displayName, email: email,
                                           role: .client, coachId: nil, totalGP: 0)
                try db.collection("users").document(uid).setData(from: newUser)
            }

            currentAppleNonce = nil
        } catch {
            // Don't show a banner when user simply dismissed the system sheet.
            if (error as? ASAuthorizationError)?.code == .canceled {
                return
            }
            errorMessage = error.localizedDescription
            print("❌ Apple SignIn error: \(error)")
        }
    }

    // MARK: - Account deletion

    /// The auth provider the current user signed in with (used to choose the re-auth flow).
    var primaryProviderId: String? {
        firebaseUser?.providerData.first?.providerID
    }

    /// Wipes all user data, revokes the Apple token if applicable, and deletes the Firebase user.
    /// Must be called with a *fresh* credential (Firebase requires recent login for delete).
    func deleteAccount(appleAuthorizationCode: String? = nil) async throws {
        guard let user = firebaseUser, let uid = user.uid as String? else {
            throw NSError(domain: "DeleteAccount", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Not signed in."])
        }

        // 1. Wipe Firestore data while we still have read/write permission.
        await AccountDeletionService.shared.wipeAllUserData(uid: uid)

        // 2. For Sign in with Apple users, revoke the token — required by App Review 5.1.1(v).
        //    Quietly skipped if no auth code is available; the user account is still deleted.
        if let code = appleAuthorizationCode {
            try? await Auth.auth().revokeToken(withAuthorizationCode: code)
        }

        // 3. Delete the Firebase Auth user.
        try await user.delete()
    }

    /// Re-authenticates using a fresh Apple credential — clears the "recent login required" gate.
    /// Returns the authorization code so the caller can revoke the token.
    func reauthenticateWithApple(result: Result<ASAuthorization, Error>) async throws -> String? {
        let authorization = try result.get()
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw NSError(domain: "AppleAuth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential."])
        }
        guard let nonce = currentAppleNonce else {
            throw NSError(domain: "AppleAuth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Apple nonce. Try again."])
        }
        guard let identityTokenData = credential.identityToken,
              let idTokenString = String(data: identityTokenData, encoding: .utf8) else {
            throw NSError(domain: "AppleAuth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Apple identity token."])
        }
        guard let user = firebaseUser else {
            throw NSError(domain: "AppleAuth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Not signed in."])
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        try await user.reauthenticate(with: firebaseCredential)
        currentAppleNonce = nil

        if let code = credential.authorizationCode {
            return String(data: code, encoding: .utf8)
        }
        return nil
    }

    /// Re-authenticates an email/password user before deletion.
    func reauthenticate(email: String, password: String) async throws {
        guard let user = firebaseUser else {
            throw NSError(domain: "Reauth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Not signed in."])
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }

    // MARK: - Sign Out
    func signOut() {
        LoginManager().logOut()
        try? Auth.auth().signOut()
    }

    // MARK: - Nonce helpers (Apple → Firebase requires a SHA256-hashed nonce)

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard status == errSecSuccess else {
                fatalError("SecRandomCopyBytes failed: \(status)")
            }
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private
    private func attachProfileListener(uid: String) {
        profileListener?.remove()
        profileListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    let profile = try? snapshot?.data(as: ContinuoUser.self)
                    self?.profile = profile
                    let name = profile?.displayName.trimmingCharacters(in: .whitespaces) ?? ""
                    // Any social-auth profile that still carries the "User" placeholder
                    // (or no name at all) needs to finish the welcome flow.
                    self?.needsProfileSetup = profile != nil && (name.isEmpty || name == "User")
                }
            }
    }

    // MARK: - Profile editing

    /// Finishes the welcome flow: sets the display name and role on the user's profile.
    func completeProfileSetup(displayName: String, role: UserRole) async {
        guard let uid = firebaseUser?.uid else { return }
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "User" else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "displayName": trimmed,
                "role": role.rawValue
            ])
            // Listener will re-fire and flip needsProfileSetup to false.
        } catch {
            errorMessage = error.localizedDescription
            print("❌ completeProfileSetup error: \(error)")
        }
    }

    /// Updates only the display name (used by Profile → Edit name).
    func updateDisplayName(_ name: String) async {
        guard let uid = firebaseUser?.uid else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "displayName": trimmed
            ])
        } catch {
            errorMessage = error.localizedDescription
            print("❌ updateDisplayName error: \(error)")
        }
    }
}
