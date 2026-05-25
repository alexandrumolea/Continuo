import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FacebookLogin

@MainActor
final class AuthService: ObservableObject {
    @Published var firebaseUser: User?
    @Published var profile: ContinuoUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var profileListener: ListenerRegistration?
    private var authHandle: AuthStateDidChangeListenerHandle?

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

    // MARK: - Sign Out
    func signOut() {
        LoginManager().logOut()
        try? Auth.auth().signOut()
    }

    // MARK: - Private
    private func attachProfileListener(uid: String) {
        profileListener?.remove()
        profileListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    self?.profile = try? snapshot?.data(as: ContinuoUser.self)
                }
            }
    }
}
