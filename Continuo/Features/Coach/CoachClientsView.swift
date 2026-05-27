import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CoachClientsView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var clients: [ContinuoUser] = []
    @State private var selectedClient: ContinuoUser?
    @State private var listener: ListenerRegistration?

    // Sheet routing — one per action type
    @State private var clientForSession: ContinuoUser?
    @State private var clientForAssignment: ContinuoUser?
    @State private var clientForNotes: ContinuoUser?

    private var coachId: String { auth.firebaseUser?.uid ?? "" }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        coachCodeCard
                        clientsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("My Clients")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadClients() }
            .onDisappear { listener?.remove() }

            // ── Sheets ──
            .sheet(item: $clientForSession) { client in
                CoachLogSessionView(
                    clientId: client.id ?? "",
                    clientName: client.displayName,
                    coachId: coachId
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $clientForAssignment) { client in
                SendAssignmentView(client: client, coachId: coachId)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $clientForNotes) { client in
                CoachClientNotesView(
                    coachId: coachId,
                    clientName: client.displayName,
                    clientId: client.id ?? ""
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Coach code card

    private var coachCodeCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your coach code")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                        Text(coachCode)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(ContinuoTheme.terracotta)
                            .tracking(6)
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = coachCode
                        HapticFeedback.success()
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

    // MARK: - Clients list

    private var clientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected clients (\(clients.count))")
                .font(ContinuoTheme.rounded(18, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            if clients.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Text("👥").font(.system(size: 40))
                        Text("No clients yet.\nShare your code to get started.")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(clients) { client in
                    NavigationLink(destination: CoachClientActivityView(
                        client: client,
                        coachId: coachId
                    )) {
                        ClientRow(client: client,
                                  onLogSession:    { clientForSession    = client },
                                  onSendAssignment: { clientForAssignment = client },
                                  onNotes:          { clientForNotes      = client })
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var coachCode: String {
        String((auth.firebaseUser?.uid ?? "").prefix(6)).uppercased()
    }

    private func loadClients() {
        guard let uid = auth.firebaseUser?.uid else { return }
        listener = AssignmentService.shared.clientsListener(coachId: uid) { items in
            clients = items
        }
    }
}

// MARK: - Client row

struct ClientRow: View {
    let client: ContinuoUser
    let onLogSession: () -> Void
    let onSendAssignment: () -> Void
    let onNotes: () -> Void

    @State private var sessionCount: Int = 0

    private var tier: (name: String, color: Color) {
        switch client.totalGP {
        case 0..<200:    return ("Waking",      Color(hex: "7B9CB8"))
        case 200..<450:  return ("Seeking",     Color(hex: "C4873A"))
        case 450..<700:  return ("Emerging",    Color(hex: "4E7040"))
        case 700..<2500: return ("Aligned",     Color(hex: "2D9B8A"))
        case 2500..<5000:return ("Flourishing", Color(hex: "C4A020"))
        default:         return ("Sage",        Color(hex: "7B5EA7"))
        }
    }

    var body: some View {
        GlassCard {
            VStack(spacing: 14) {

                // ── Identity row ──
                HStack(spacing: 14) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(ContinuoTheme.olive.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Text(initials)
                            .font(ContinuoTheme.rounded(16, weight: .bold))
                            .foregroundColor(ContinuoTheme.olive)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(client.displayName)
                            .font(ContinuoTheme.rounded(15, weight: .medium))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text(client.email)
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }

                    Spacer()

                    // Quick stats
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(client.totalGP)")
                            .font(ContinuoTheme.rounded(16, weight: .bold))
                            .foregroundColor(ContinuoTheme.sunOrange)
                        Text(tier.name)
                            .font(ContinuoTheme.rounded(10, weight: .semibold))
                            .foregroundColor(tier.color)
                    }
                }

                Divider().opacity(0.25)

                // ── 3 action buttons ──
                HStack(spacing: 10) {
                    actionButton(
                        icon: "calendar.badge.plus",
                        label: "Log Session",
                        color: Color(hex: "6E443C"),
                        action: onLogSession
                    )
                    actionButton(
                        icon: "paperplane.fill",
                        label: "Assignment",
                        color: ContinuoTheme.sunYellow,
                        action: onSendAssignment
                    )
                    actionButton(
                        icon: "note.text",
                        label: "Notes",
                        color: Color(hex: "7B5EA7"),
                        action: onNotes
                    )
                }
            }
        }
        .task {
            if let id = client.id {
                let snap = try? await Firestore.firestore()
                    .collection("coachingSessions")
                    .whereField("userId", isEqualTo: id)
                    .getDocuments()
                sessionCount = snap?.documents.count ?? 0
            }
        }
    }

    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticFeedback.selection()
            action()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(color)
                Text(label)
                    .font(ContinuoTheme.rounded(11, weight: .semibold))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.18), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let parts = client.displayName.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)) }
        return String(client.displayName.prefix(2)).uppercased()
    }
}
