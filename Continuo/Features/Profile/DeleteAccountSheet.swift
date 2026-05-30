import SwiftUI
import AuthenticationServices
import FirebaseAuth

/// Two-step deletion: confirmation + re-authentication via the original provider.
/// On success the user is fully wiped (Firestore + Auth) and signed out automatically.
struct DeleteAccountSheet: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var confirmText: String = ""
    @State private var emailReauthPassword: String = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @FocusState private var confirmFocused: Bool

    private var providerId: String? { auth.primaryProviderId }

    private var requiresEmailPassword: Bool { providerId == "password" }

    /// The user must type DELETE to enable the destructive button (or fill password for email users).
    private var canProceed: Bool {
        let trimmed = confirmText.trimmingCharacters(in: .whitespaces).uppercased()
        if requiresEmailPassword {
            return trimmed == "DELETE" && !emailReauthPassword.isEmpty
        }
        return trimmed == "DELETE"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        whatGetsDeletedCard
                        confirmField
                        if requiresEmailPassword { passwordField }
                        if let msg = errorMessage { errorBanner(msg) }
                        actionButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Delete account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ContinuoTheme.textMedium)
                }
            }
        }
        .interactiveDismissDisabled(isDeleting)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.red)
            Text("This is permanent.")
                .font(ContinuoTheme.rounded(20, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)
            Text("Deleting your account removes your profile, progress, journey, and any connections to coaches or clients. We can't recover it later.")
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.textMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var whatGetsDeletedCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("What gets deleted")
                    .font(ContinuoTheme.rounded(13, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                bullet("Your profile, name, and growth points")
                bullet("All daily practices, goals, and reflections")
                bullet("Coaching sessions and private notes")
                bullet("Assignments and conversation threads")
                Divider().padding(.vertical, 4).opacity(0.4)
                bullet("Mindfulness minutes already saved to Apple Health stay there — Apple controls Health data, not us.", muted: true)
            }
        }
    }

    private func bullet(_ text: String, muted: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(muted ? ContinuoTheme.textLight : ContinuoTheme.terracotta)
                .frame(width: 4, height: 4).padding(.top, 7)
            Text(text)
                .font(ContinuoTheme.rounded(12))
                .foregroundColor(muted ? ContinuoTheme.textLight : ContinuoTheme.textMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var confirmField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type DELETE to confirm")
                .font(ContinuoTheme.rounded(12))
                .foregroundColor(ContinuoTheme.textMedium)
            TextField("DELETE", text: $confirmText)
                .font(ContinuoTheme.rounded(15, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .focused($confirmFocused)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1.5))
                )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirm your password")
                .font(ContinuoTheme.rounded(12))
                .foregroundColor(ContinuoTheme.textMedium)
            SecureField("Password", text: $emailReauthPassword)
                .font(ContinuoTheme.rounded(15))
                .foregroundColor(ContinuoTheme.charcoal)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "E8E0D6"), lineWidth: 1.5))
                )
        }
    }

    private func errorBanner(_ text: String) -> some View {
        Text(text)
            .font(ContinuoTheme.rounded(13))
            .foregroundColor(.red)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.08)))
    }

    /// Branches on provider: Apple gets a native button (handles re-auth + token revocation),
    /// Google relies on a recent login (typical right after sign in), email uses the password field above.
    @ViewBuilder
    private var actionButton: some View {
        if providerId == "apple.com" {
            VStack(spacing: 8) {
                Text("Confirm with Apple to delete")
                    .font(ContinuoTheme.rounded(12))
                    .foregroundColor(ContinuoTheme.textMedium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SignInWithAppleButton(
                    .continue,
                    onRequest: { auth.prepareAppleRequest($0) },
                    onCompletion: { result in
                        Task { await runAppleDeletion(result: result) }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(14)
                .disabled(!canProceed || isDeleting)
                .opacity((!canProceed || isDeleting) ? 0.4 : 1)
            }
        } else {
            Button {
                Task { await runStandardDeletion() }
            } label: {
                HStack(spacing: 8) {
                    if isDeleting { ProgressView().tint(.white) }
                    Text(isDeleting ? "Deleting…" : "Delete my account")
                        .font(ContinuoTheme.rounded(16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.red))
                .foregroundColor(.white)
            }
            .disabled(!canProceed || isDeleting)
            .opacity((!canProceed || isDeleting) ? 0.5 : 1)
        }
    }

    // MARK: - Actions

    private func runAppleDeletion(result: Result<ASAuthorization, Error>) async {
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }
        do {
            let authCode = try await auth.reauthenticateWithApple(result: result)
            try await auth.deleteAccount(appleAuthorizationCode: authCode)
            HapticFeedback.success()
            // The auth state listener will swap to AuthView automatically.
        } catch {
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription
            print("❌ deleteAccount (Apple): \(error)")
        }
    }

    private func runStandardDeletion() async {
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }
        do {
            if requiresEmailPassword,
               let email = auth.firebaseUser?.email {
                try await auth.reauthenticate(email: email, password: emailReauthPassword)
            }
            try await auth.deleteAccount(appleAuthorizationCode: nil)
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ deleteAccount: \(error)")
        }
    }
}
