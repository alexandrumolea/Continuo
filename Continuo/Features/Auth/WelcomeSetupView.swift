import SwiftUI

/// First-run setup shown after Apple/Google sign in (or any time the profile name is missing).
/// User picks display name + role here — required before they can use the app.
struct WelcomeSetupView: View {
    @EnvironmentObject private var auth: AuthService

    @State private var displayName: String = ""
    @State private var role: UserRole = .client
    @State private var agreedToTerms = false
    @State private var showTermsError = false
    @State private var isSaving = false
    @FocusState private var nameFocused: Bool

    /// Form-level validity — consent is checked separately at tap-time so we can
    /// give the user an explicit error message instead of silently disabling the button.
    private var canContinue: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed != "User"
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    nameField
                    roleSelector
                    TermsAgreementRow(agreed: $agreedToTerms,
                                      showError: $showTermsError)
                    continueButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            // Pre-fill from any name we already had (probably empty / "User")
            let existing = auth.profile?.displayName ?? ""
            if existing != "User", !existing.isEmpty {
                displayName = existing
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { nameFocused = true }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 14) {
            Image("ContinuoOwl")
                .resizable().scaledToFit()
                .frame(width: 90, height: 90)
                .shadow(color: Color(hex: "7A5230").opacity(0.25), radius: 18, x: -3, y: 10)
                .blendMode(.multiply)
            Text("Welcome to Continuo")
                .font(ContinuoTheme.rounded(26, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)
                .multilineTextAlignment(.center)
            Text("Let's finish setting up your profile.")
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.textMedium)
                .multilineTextAlignment(.center)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your name")
                .font(ContinuoTheme.rounded(12))
                .foregroundColor(ContinuoTheme.textMedium)
            AuthField(icon: "person.fill", placeholder: "How should we call you?",
                      text: $displayName)
                .focused($nameFocused)
        }
    }

    private var roleSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("I am a…")
                .font(ContinuoTheme.rounded(12))
                .foregroundColor(ContinuoTheme.textMedium)
            HStack(spacing: 12) {
                ForEach(UserRole.allCases, id: \.self) { option in
                    Button {
                        HapticFeedback.selection()
                        withAnimation(.easeInOut(duration: 0.15)) { role = option }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: option.icon)
                            Text(option.displayName)
                                .font(ContinuoTheme.rounded(14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(role == option ? ContinuoTheme.terracotta : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(role == option
                                        ? Color.clear
                                        : ContinuoTheme.charcoal.opacity(0.18), lineWidth: 1)
                        )
                        .foregroundColor(role == option ? .white : ContinuoTheme.textMedium)
                    }
                }
            }
        }
    }

    private var continueButton: some View {
        PrimaryButton(title: isSaving ? "Saving…" : "Continue", isLoading: isSaving) {
            // Surface a clear error when consent is missing (matches the email signup flow).
            if !agreedToTerms {
                HapticFeedback.medium()
                withAnimation(.easeInOut(duration: 0.2)) { showTermsError = true }
                return
            }
            Task {
                isSaving = true
                await auth.completeProfileSetup(displayName: displayName, role: role)
                isSaving = false
                HapticFeedback.success()
            }
        }
        .disabled(!canContinue || isSaving)
    }
}

#Preview {
    WelcomeSetupView().environmentObject(AuthService())
}
