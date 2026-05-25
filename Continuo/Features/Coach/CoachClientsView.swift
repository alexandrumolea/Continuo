import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CoachClientsView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var clients: [ContinuoUser] = []
    @State private var selectedClient: ContinuoUser?
    @State private var listener: ListenerRegistration?

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
            .sheet(item: $selectedClient) { client in
                SendAssignmentView(client: client, coachId: auth.firebaseUser?.uid ?? "")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear { loadClients() }
            .onDisappear { listener?.remove() }
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
                        coachId: auth.firebaseUser?.uid ?? ""
                    )) {
                        ClientRow(client: client) {
                            selectedClient = client
                        }
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
    let onSend: () -> Void

    @State private var sessionCount: Int = 0

    private var tier: (emoji: String, name: String) {
        let gp = client.totalGP
        switch gp {
        case 0..<100:   return ("🌱", "Seedling")
        case 100..<300: return ("🌿", "Sprout")
        case 300..<600: return ("🌸", "Bloom")
        case 600..<1000: return ("🌳", "Flourish")
        default:        return ("✨", "Radiant")
        }
    }

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
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

                    Button(action: onSend) {
                        HStack(spacing: 4) {
                            Image(systemName: "paperplane.fill")
                                .font(.caption)
                            Text("Send")
                                .font(ContinuoTheme.rounded(13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(ContinuoTheme.sunYellow))
                    }
                }

                // Stats strip
                HStack(spacing: 0) {
                    statPill(emoji: "🤝", value: "\(sessionCount)", label: "sessions")
                    Spacer()
                    statPill(emoji: tier.emoji, value: tier.name, label: "level")
                    Spacer()
                    statPill(emoji: "⭐", value: "\(client.totalGP)", label: "GP")
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

    private func statPill(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(emoji).font(.system(size: 13))
                Text(value)
                    .font(ContinuoTheme.rounded(13, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
            }
            Text(label)
                .font(ContinuoTheme.rounded(10))
                .foregroundColor(ContinuoTheme.textLight)
        }
    }

    private var initials: String {
        let parts = client.displayName.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)) }
        return String(client.displayName.prefix(2)).uppercased()
    }
}
