import SwiftUI

struct AuthView: View {
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    logoSection
                    modeToggle
                    formSection
                    if let err = auth.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    PrimaryButton(title: vm.isLoginMode ? "Sign In" : "Start my journey",
                                  isLoading: auth.isLoading) {
                        vm.submit(using: auth)
                    }
                    .padding(.horizontal, 24)
                    .disabled(!vm.canSubmit)

                    // Divider
                    HStack {
                        Rectangle().fill(ContinuoTheme.charcoal.opacity(0.15)).frame(height: 1)
                        Text("or").font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textMedium)
                        Rectangle().fill(ContinuoTheme.charcoal.opacity(0.15)).frame(height: 1)
                    }
                    .padding(.horizontal, 24)

                    // Facebook button
                    Button {
                        Task { await auth.signInWithFacebook() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "f.square.fill")
                                .font(.title3)
                            Text("Continue with Facebook")
                                .font(ContinuoTheme.rounded(16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "1877F2")))
                        .foregroundColor(.white)
                        .shadow(color: Color(hex: "1877F2").opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .disabled(auth.isLoading)
                }
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Logo
    private var logoSection: some View {
        VStack(spacing: 10) {
            Text("∞")
                .font(.system(size: 64))
                .foregroundColor(ContinuoTheme.sunOrange)
            Text("Continuo")
                .font(ContinuoTheme.rounded(38, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)
            Text("Your thread of growth")
                .font(ContinuoTheme.rounded(15))
                .foregroundColor(ContinuoTheme.textMedium)
        }
        .padding(.top, 72)
    }

    // MARK: - Mode toggle
    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach([("Sign In", true), ("Create Account", false)], id: \.0) { label, isLogin in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { vm.isLoginMode = isLogin }
                } label: {
                    Text(label)
                        .font(ContinuoTheme.rounded(14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(vm.isLoginMode == isLogin
                                      ? ContinuoTheme.sunOrange
                                      : Color.clear)
                        )
                        .foregroundColor(vm.isLoginMode == isLogin
                                         ? .white
                                         : ContinuoTheme.textMedium)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.7), lineWidth: 1))
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Form
    private var formSection: some View {
        VStack(spacing: 14) {
            if !vm.isLoginMode {
                AuthField(icon: "person.fill",    placeholder: "Display name",  text: $vm.displayName)
            }
            AuthField(icon: "envelope.fill",  placeholder: "Email",          text: $vm.email, keyboard: .emailAddress)
            AuthField(icon: "lock.fill",       placeholder: "Password",       text: $vm.password, isSecure: true)

            if !vm.isLoginMode {
                roleSelector
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Role selector
    private var roleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("I am a…")
                .font(ContinuoTheme.rounded(12))
                .foregroundColor(ContinuoTheme.textMedium)
            HStack(spacing: 12) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    Button {
                        withAnimation { vm.selectedRole = role }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: role.icon)
                            Text(role.displayName)
                                .font(ContinuoTheme.rounded(14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(vm.selectedRole == role
                                      ? ContinuoTheme.terracotta
                                      : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(vm.selectedRole == role
                                        ? Color.clear
                                        : ContinuoTheme.charcoal.opacity(0.18), lineWidth: 1)
                        )
                        .foregroundColor(vm.selectedRole == role
                                         ? .white
                                         : ContinuoTheme.textMedium)
                    }
                }
            }
        }
    }
}

// MARK: - Reusable text field
struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(ContinuoTheme.textLight)
                .frame(width: 20)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .font(ContinuoTheme.rounded(15))
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.7), lineWidth: 1))
        )
    }
}

#Preview {
    AuthView().environmentObject(AuthService())
}
