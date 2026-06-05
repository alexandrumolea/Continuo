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

// MARK: - Practice timeline row

struct CoachPracticeTimelineRow: View {
    let entry: CoachPracticeEntry
    let isLast: Bool
    var onDelete: (() -> Void)? = nil

    @State private var swipeOffset: CGFloat = 0
    private let deleteWidth: CGFloat = 68

    private var practice: CoachPractice? {
        CoachPractice.catalog.first { $0.id == entry.practiceId }
    }

    /// Ordered prompt → answer pairs for reflection-form entries.
    private var orderedResponses: [(prompt: String, answer: String)] {
        guard case .reflectionForm(let prompts) = practice?.type else { return [] }
        return prompts.compactMap { prompt in
            guard let val = entry.responses[prompt],
                  !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }
            return (prompt, val)
        }
    }

    private var accentColor: Color {
        practice?.categoryColor ?? ContinuoTheme.sunYellow
    }

    private var cardBg: Color {
        practice?.cardColor ?? Color.white.opacity(0.6)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if onDelete != nil {
                Button {
                    HapticFeedback.medium()
                    withAnimation(.spring(response: 0.25)) { swipeOffset = 0 }
                    onDelete?()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill").font(.system(size: 16))
                        Text("Delete").font(ContinuoTheme.rounded(10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteWidth)
                    .frame(maxHeight: .infinity)
                }
                .background(Color.red.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(swipeOffset < -8 ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: swipeOffset)
            }

            rowContent
                .offset(x: swipeOffset)
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onChanged { val in
                            guard onDelete != nil, val.translation.width < 0 else { return }
                            swipeOffset = max(val.translation.width, -deleteWidth)
                        }
                        .onEnded { val in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                swipeOffset = val.translation.width < -(deleteWidth / 2) ? -deleteWidth : 0
                            }
                        }
                )
                .onTapGesture {
                    if swipeOffset < 0 {
                        withAnimation(.spring(response: 0.25)) { swipeOffset = 0 }
                    }
                }
        }
        .clipped()
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline column
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Text(entry.practiceEmoji)
                        .font(.system(size: 16))
                }
                if !isLast {
                    Rectangle()
                        .fill(ContinuoTheme.charcoal.opacity(0.1))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }

            // Content column
            VStack(alignment: .leading, spacing: 8) {

                // Practice title + relative time
                HStack {
                    Text(entry.practiceTitle)
                        .font(ContinuoTheme.rounded(14, weight: .medium))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Spacer()
                    Text(entry.date, style: .relative)
                        .font(.caption2)
                        .foregroundColor(ContinuoTheme.textLight)
                }

                // ── Category highlight (Perspective Change) ─────────────
                if let qs = entry.categoryQuestions, !qs.isEmpty,
                   let categoryName = entry.questionText {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(categoryName)
                            .font(ContinuoTheme.rounded(14, weight: .bold))
                            .foregroundColor(accentColor)

                        Divider().opacity(0.35)

                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(qs.indices, id: \.self) { i in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("·")
                                        .font(ContinuoTheme.rounded(14, weight: .bold))
                                        .foregroundColor(accentColor.opacity(0.5))
                                    Text(qs[i])
                                        .font(ContinuoTheme.rounded(13))
                                        .foregroundColor(ContinuoTheme.charcoal.opacity(0.85))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBg.opacity(0.6))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
                    )

                // ── Single-question highlight ────────────────────────────
                } else if let q = entry.questionText, !q.isEmpty, orderedResponses.isEmpty {
                    Text(q)
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.charcoal.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardBg.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentColor.opacity(0.2), lineWidth: 1))
                        )

                // ── Reflection-form entries ──────────────────────────────
                } else if !orderedResponses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(orderedResponses.indices, id: \.self) { idx in
                            let pair = orderedResponses[idx]
                            VStack(alignment: .leading, spacing: 3) {
                                Text(pair.prompt)
                                    .font(ContinuoTheme.rounded(11, weight: .semibold))
                                    .foregroundColor(accentColor.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(pair.answer)
                                    .font(ContinuoTheme.rounded(13))
                                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.85))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if idx < orderedResponses.count - 1 {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBg.opacity(0.6))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
                    )
                }
            }
            .padding(.top, 8)
            .padding(.bottom, isLast ? 0 : 22)
        }
        .contentShape(Rectangle())
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
