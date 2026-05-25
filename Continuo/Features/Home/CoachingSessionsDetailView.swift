import SwiftUI
import FirebaseFirestore

struct CoachingSessionsDetailView: View {
    let userId: String

    @State private var sessions: [CoachingSession] = []
    @State private var listener: ListenerRegistration?
    @State private var showLog = false
    @State private var editingSession: CoachingSession? = nil
    @State private var deleteTarget: CoachingSession? = nil
    @State private var showDeleteAlert = false

    private let accent = Color(hex: "6E443C")

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🤝")
                            .font(.system(size: 44))
                        Text("Coaching Sessions")
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("Each session earns you +30 GP")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(accent.opacity(0.65))
                    }
                    .padding(.top, 4)

                    // ── Log button ──
                    Button { showLog = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Log a session")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                            Spacer()
                            Text("+30 GP")
                                .font(ContinuoTheme.rounded(13, weight: .bold))
                                .foregroundColor(ContinuoTheme.sunYellow)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(ContinuoTheme.sunYellow.opacity(0.15)))
                        }
                        .foregroundColor(accent)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(accent.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(accent.opacity(0.18), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)

                    // ── Timeline ──
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(sessions.count) session\(sessions.count == 1 ? "" : "s")")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)

                            VStack(spacing: 0) {
                                ForEach(Array(sessions.enumerated()), id: \.element.id) { idx, session in
                                    sessionRow(session, isLast: idx == sessions.count - 1)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            listener = CoachingSessionService.shared.sessionsListener(userId: userId) { sessions = $0 }
        }
        .onDisappear { listener?.remove() }
        .sheet(isPresented: $showLog) {
            LogCoachingSessionView(userId: userId)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingSession) { session in
            LogCoachingSessionView(userId: userId, existingSession: session)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Delete session?", isPresented: $showDeleteAlert, presenting: deleteTarget) { target in
            Button("Delete", role: .destructive) {
                Task { try? await CoachingSessionService.shared.deleteSession(target) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { target in
            Text("This will remove the session and deduct \(target.gpEarned) GP from your total.")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundColor(ContinuoTheme.sunYellow)
            Text("Log your first coaching session above.")
                .font(ContinuoTheme.rounded(13, weight: .medium))
                .foregroundColor(accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(ContinuoTheme.sunYellow.opacity(0.1)))
    }

    // MARK: - Timeline row

    private func sessionRow(_ session: CoachingSession, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {

            // Timeline track
            VStack(spacing: 0) {
                Circle()
                    .fill(accent)
                    .frame(width: 9, height: 9)
                    .padding(.top, 6)
                if !isLast {
                    Rectangle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 9)

            // Content
            VStack(alignment: .leading, spacing: 10) {

                // Date + menu
                HStack(alignment: .top) {
                    Text(session.sessionDate, style: .date)
                        .font(ContinuoTheme.rounded(15, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Spacer()
                    Menu {
                        Button { editingSession = session } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deleteTarget = session
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(ContinuoTheme.textLight)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    }
                }

                // Conclusions
                if !session.conclusions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CONCLUSIONS")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(accent.opacity(0.55))
                            .kerning(0.7)
                        Text(session.conclusions)
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accent.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(accent.opacity(0.12), lineWidth: 1))
                    )
                }

                // Actions
                if !session.actions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACTIONS")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(ContinuoTheme.olive.opacity(0.65))
                            .kerning(0.7)
                        Text(session.actions)
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ContinuoTheme.olive.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(ContinuoTheme.olive.opacity(0.15), lineWidth: 1))
                    )
                }

                // No notes
                if session.conclusions.isEmpty && session.actions.isEmpty {
                    Text("Session logged — no notes added.")
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textLight)
                        .italic()
                }
            }
            .padding(.bottom, isLast ? 0 : 24)
        }
    }
}
