import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var showSignOutAlert = false
    @State private var showEditName = false
    @State private var showDeleteAccount = false
    @State private var passwordResetAlert: PasswordResetAlert? = nil

    // Client: coach connection
    @State private var coachCodeInput = ""
    @State private var isConnecting = false
    @State private var connectionMessage: String? = nil
    @State private var connectionSuccess = false
    @State private var showChangeCoach = false
    @FocusState private var codeFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        avatarSection
                        infoCard
                        coachSection          // role-dependent card
                        actionsCard
                        signOutButton
                        deleteAccountButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { auth.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showEditName) {
                EditDisplayNameSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showDeleteAccount) {
                DeleteAccountSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .alert(item: $passwordResetAlert) { alert in
                Alert(title: Text(alert.title),
                      message: Text(alert.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Role-dependent section
    @ViewBuilder
    private var coachSection: some View {
        if auth.profile?.role == .coach {
            coachCodeCard
        } else {
            connectToCoachCard
        }
    }

    // MARK: - Coach code card
    private var coachCodeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your coach code")
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(ContinuoTheme.textMedium)

                HStack {
                    Text(myCoachCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(ContinuoTheme.terracotta)
                        .tracking(6)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = myCoachCode
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.title3)
                            .foregroundColor(ContinuoTheme.sunYellow)
                            .padding(10)
                            .background(Circle().fill(ContinuoTheme.sunYellow.opacity(0.12)))
                    }
                }

                Text("Share this code with your clients so they can connect with you.")
                    .font(ContinuoTheme.rounded(12))
                    .foregroundColor(ContinuoTheme.textLight)
            }
        }
    }

    // MARK: - Client connect card
    private var connectToCoachCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(ContinuoTheme.olive)
                    Text(auth.profile?.coachId != nil ? "Connected to a coach" : "Connect to your coach")
                        .font(ContinuoTheme.rounded(15, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                }

                if auth.profile?.coachId != nil && !showChangeCoach {
                    // Already connected — show status + change option
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ContinuoTheme.olive)
                        Text("You're connected! Your coach can send you assignments.")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textMedium)
                        Spacer()
                        Button {
                            showChangeCoach = true
                            connectionMessage = nil
                            coachCodeInput = ""
                        } label: {
                            Text("Change")
                                .font(ContinuoTheme.rounded(12, weight: .semibold))
                                .foregroundColor(ContinuoTheme.terracotta)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(ContinuoTheme.terracotta.opacity(0.1)))
                        }
                    }
                } else {
                    // Connection / Change-coach form
                    if showChangeCoach {
                        Text("Enter your new coach's code")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }

                    HStack(spacing: 10) {
                        TextField("Enter 6-digit code", text: $coachCodeInput)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .focused($codeFocused)
                            .onChange(of: coachCodeInput) { _, val in
                                coachCodeInput = String(val.uppercased().prefix(6))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.9))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "EDE8E0"), lineWidth: 1)))

                        Button {
                            connectToCoach()
                        } label: {
                            Group {
                                if isConnecting {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                } else {
                                    Text(showChangeCoach ? "Switch" : "Connect")
                                        .font(ContinuoTheme.rounded(14, weight: .semibold))
                                }
                            }
                            .frame(width: 88, height: 38)
                            .background(Capsule().fill(
                                coachCodeInput.count == 6
                                    ? ContinuoTheme.sunYellow
                                    : ContinuoTheme.textLight.opacity(0.4)
                            ))
                            .foregroundColor(.white)
                        }
                        .disabled(coachCodeInput.count < 6 || isConnecting)
                    }

                    if showChangeCoach {
                        Button {
                            showChangeCoach = false
                            coachCodeInput = ""
                            connectionMessage = nil
                        } label: {
                            Text("Cancel")
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                    }

                    if let msg = connectionMessage {
                        HStack(spacing: 6) {
                            Image(systemName: connectionSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            Text(msg)
                                .font(ContinuoTheme.rounded(12))
                        }
                        .foregroundColor(connectionSuccess ? ContinuoTheme.olive : .red)
                    }
                }
            }
        }
    }

    // MARK: - Avatar
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ContinuoTheme.sunOrange.opacity(0.15))
                    .frame(width: 90, height: 90)
                Text(initials)
                    .font(ContinuoTheme.rounded(32, weight: .bold))
                    .foregroundColor(ContinuoTheme.sunOrange)
            }
            .shadow(color: ContinuoTheme.sunOrange.opacity(0.2), radius: 12)

            Text(auth.profile?.displayName ?? "")
                .font(ContinuoTheme.rounded(22, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)

            Text(auth.profile?.email ?? "")
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.textMedium)

            // Role badge
            HStack(spacing: 6) {
                Image(systemName: auth.profile?.role.icon ?? "person.fill")
                    .font(.caption)
                Text(auth.profile?.role.displayName ?? "")
                    .font(ContinuoTheme.rounded(12, weight: .semibold))
            }
            .foregroundColor(ContinuoTheme.terracotta)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(ContinuoTheme.terracotta.opacity(0.1)))
        }
        .padding(.top, 12)
    }

    // MARK: - Info card
    private var infoCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                infoRow(icon: "star.fill",
                        color: ContinuoTheme.sunOrange,
                        label: "Growth Points",
                        value: "\(auth.profile?.totalGP ?? 0) GP")
                Divider().opacity(0.3).padding(.vertical, 4)
                infoRow(icon: "∞",
                        color: ContinuoTheme.olive,
                        label: "Member since",
                        value: memberSince)
            }
        }
    }

    // MARK: - Actions card
    private var actionsCard: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 0) {
                actionRow(icon: "person.fill", color: ContinuoTheme.terracotta, label: "Edit name") {
                    HapticFeedback.selection()
                    showEditName = true
                }
                Divider().padding(.leading, 52).opacity(0.3)
                actionRow(icon: "bell.fill", color: ContinuoTheme.sunOrange, label: "Notifications") {}
                Divider().padding(.leading, 52).opacity(0.3)
                actionRow(icon: "lock.fill", color: Color(hex: "7B5EA7"), label: "Change Password") {
                    HapticFeedback.selection()
                    handleChangePassword()
                }
                Divider().padding(.leading, 52).opacity(0.3)
                actionRow(icon: "questionmark.circle.fill", color: ContinuoTheme.olive, label: "Help & Support") {
                    HapticFeedback.selection()
                    openSupportEmail()
                }
                Divider().padding(.leading, 52).opacity(0.3)
                actionRow(icon: "hand.raised.fill", color: ContinuoTheme.textMedium, label: "Privacy Policy") {
                    HapticFeedback.selection()
                    if let url = URL(string: "https://alexandrumolea.github.io/Continuo/") {
                        UIApplication.shared.open(url)
                    }
                }
                Divider().padding(.leading, 52).opacity(0.3)
                actionRow(icon: "doc.text.fill", color: ContinuoTheme.textMedium, label: "Terms of Service") {
                    HapticFeedback.selection()
                    if let url = URL(string: "https://alexandrumolea.github.io/Continuo/terms/") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - Sign out
    private var signOutButton: some View {
        Button {
            showSignOutAlert = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .font(ContinuoTheme.rounded(16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.1)))
            .foregroundColor(.red)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.2), lineWidth: 1))
        }
        .padding(.top, 8)
    }

    // MARK: - Delete account (App Store guideline 5.1.1(v))
    private var deleteAccountButton: some View {
        Button {
            HapticFeedback.medium()
            showDeleteAccount = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                Text("Delete account")
                    .font(ContinuoTheme.rounded(13, weight: .medium))
            }
            .foregroundColor(ContinuoTheme.textLight)
            .padding(.vertical, 10).padding(.horizontal, 14)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers
    private var myCoachCode: String {
        String((auth.firebaseUser?.uid ?? "").prefix(6)).uppercased()
    }

    private func connectToCoach() {
        guard coachCodeInput.count == 6,
              let clientId = auth.firebaseUser?.uid else { return }
        isConnecting = true
        connectionMessage = nil

        AssignmentService.shared.findCoach(byCode: coachCodeInput) { coach in
            guard let coach = coach, let coachId = coach.id else {
                DispatchQueue.main.async {
                    self.connectionMessage = "No coach found with that code."
                    self.connectionSuccess = false
                    self.isConnecting = false
                }
                return
            }
            Task {
                do {
                    try await AssignmentService.shared.connectToCoach(clientId: clientId, coachId: coachId)
                    await MainActor.run {
                        self.connectionMessage = "Connected to \(coach.displayName)!"
                        self.connectionSuccess = true
                        self.isConnecting = false
                        self.coachCodeInput = ""
                        self.codeFocused = false
                        self.showChangeCoach = false
                    }
                } catch {
                    await MainActor.run {
                        self.connectionMessage = "Connection failed. Please try again."
                        self.connectionSuccess = false
                        self.isConnecting = false
                    }
                }
            }
        }
    }

    private var initials: String {
        let name = auth.profile?.displayName ?? ""
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }

    private var memberSince: String {
        guard let date = auth.firebaseUser?.metadata.creationDate else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    private func infoRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 34, height: 34)
                if icon == "∞" {
                    Text("∞").font(.system(size: 16)).foregroundColor(color)
                } else {
                    Image(systemName: icon).font(.caption).foregroundColor(color)
                }
            }
            Text(label)
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.charcoal.opacity(0.7))
            Spacer()
            Text(value)
                .font(ContinuoTheme.rounded(14, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Change Password / Help & Support actions

    /// Email/password users get a Firebase reset link. Social-auth users (Apple/Google)
    /// can't change a password in our app — direct them to their identity provider.
    private func handleChangePassword() {
        let provider = auth.primaryProviderId ?? "password"
        switch provider {
        case "password":
            guard let email = auth.profile?.email, !email.isEmpty else {
                passwordResetAlert = PasswordResetAlert(
                    title: "No email on file",
                    message: "We can't send a reset link without a saved email address."
                )
                return
            }
            Task {
                do {
                    try await auth.sendPasswordReset(email: email)
                    passwordResetAlert = PasswordResetAlert(
                        title: "Check your inbox",
                        message: "We sent a password reset link to \(email)."
                    )
                } catch {
                    passwordResetAlert = PasswordResetAlert(
                        title: "Couldn't send reset",
                        message: error.localizedDescription
                    )
                }
            }
        case "apple.com":
            passwordResetAlert = PasswordResetAlert(
                title: "Managed by Apple",
                message: "You signed in with Apple — your password is managed in Settings → Apple ID."
            )
        case "google.com":
            passwordResetAlert = PasswordResetAlert(
                title: "Managed by Google",
                message: "You signed in with Google — change your password at myaccount.google.com/security."
            )
        default:
            passwordResetAlert = PasswordResetAlert(
                title: "Can't change password",
                message: "Your account is managed by your identity provider."
            )
        }
    }

    private func openSupportEmail() {
        let address = "alexandru.molea@bemore.ro"
        let subject = "Continuo Support"
        let bodyLines = [
            "",
            "—",
            "App: Continuo",
            "User: \(auth.profile?.displayName ?? "—")",
            "Role: \(auth.profile?.role.displayName ?? "—")"
        ]
        let body = bodyLines.joined(separator: "\n")

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }

    private func actionRow(icon: String, color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.caption).foregroundColor(color)
                }
                .padding(.leading, 4)
                Text(label)
                    .font(ContinuoTheme.rounded(15))
                    .foregroundColor(ContinuoTheme.charcoal)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ContinuoTheme.textLight)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Alert model

private struct PasswordResetAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#Preview {
    ProfileView().environmentObject(AuthService())
}
