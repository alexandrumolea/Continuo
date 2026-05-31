import SwiftUI
import FirebaseFirestore

struct CoachClientActivityView: View {
    let client: ContinuoUser
    let coachId: String

    // Sessions — listener kept here so the summary card reflects live data
    @State private var sessions: [CoachingSession] = []
    @State private var sessionsListener: ListenerRegistration?

    // Assignments
    @State private var assignments: [Assignment] = []
    @State private var completions: [AssignmentCompletion] = []
    @State private var assignmentsListener: ListenerRegistration?
    @State private var completionsListener: ListenerRegistration?
    @State private var expandedAssignmentId: String? = nil

    // Shared goals
    @State private var sharedGoals: [Goal] = []
    @State private var goalsListener: ListenerRegistration?

    // Notes card
    @State private var hasNotes = false
    @State private var showNotes = false

    private let accent = Color(hex: "6E443C")

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // ── 1. Coaching Sessions card ──
                    NavigationLink(destination: CoachClientSessionsView(
                        client: client, coachId: coachId
                    )) {
                        summaryCard(
                            icon: "🤝",
                            title: "Coaching Sessions",
                            subtitle: sessions.isEmpty
                                ? "No sessions yet"
                                : "\(sessions.count) session\(sessions.count == 1 ? "" : "s") · +30 GP each",
                            tint: accent
                        )
                    }
                    .buttonStyle(.plain)

                    // ── 2. Client Notes card ──
                    Button { HapticFeedback.selection(); showNotes = true } label: {
                        summaryCard(
                            icon: "📝",
                            title: "Client Notes",
                            subtitle: hasNotes ? "Notes saved" : "No notes yet",
                            tint: Color(hex: "7B5EA7"),
                            badge: "Private"
                        )
                    }
                    .buttonStyle(.plain)

                    // ── 3. Shared Goals ──
                    if !sharedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "target")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.olive)
                                Text("Shared Goals")
                                    .font(ContinuoTheme.rounded(18, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.charcoal)
                            }
                            .padding(.top, 8)

                            ForEach(sharedGoals) { goal in
                                CoachClientGoalRow(goal: goal, clientName: client.displayName)
                            }
                        }
                    }

                    // ── 4. Assignments ──
                    if !assignments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Assignments")
                                .font(ContinuoTheme.rounded(18, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .padding(.top, 8)

                            ForEach(assignments) { assignment in
                                CoachAssignmentRow(
                                    assignment: assignment,
                                    completions: completionsFor(assignment),
                                    clientName: client.displayName,
                                    isExpanded: expandedAssignmentId == assignment.id,
                                    onToggleExpand: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            expandedAssignmentId =
                                                expandedAssignmentId == assignment.id ? nil : assignment.id
                                        }
                                    },
                                    onDelete: {
                                        Task { try? await AssignmentService.shared.deleteAssignment(assignment) }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(client.displayName)
        .navigationBarTitleDisplayMode(.large)
        .onAppear { startListeners() }
        .onDisappear { stopListeners() }
        .sheet(isPresented: $showNotes) {
            CoachClientNotesView(
                coachId: coachId,
                clientName: client.displayName,
                clientId: client.id ?? ""
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .onDisappear { checkNotes() }   // refresh badge after editing
        }
    }

    // MARK: - Summary card

    private func summaryCard(icon: String, title: String, subtitle: String,
                             tint: Color, badge: String? = nil) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tint.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Text(icon).font(.title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        if let badge {
                            Text(badge)
                                .font(ContinuoTheme.rounded(10, weight: .semibold))
                                .foregroundColor(tint)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(tint.opacity(0.10)))
                        }
                    }
                    Text(subtitle)
                        .font(ContinuoTheme.rounded(12))
                        .foregroundColor(ContinuoTheme.textMedium)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ContinuoTheme.textLight)
            }
        }
    }

    // MARK: - Helpers

    private func completionsFor(_ assignment: Assignment) -> [AssignmentCompletion] {
        completions
            .filter { $0.assignmentId == assignment.id }
            .sorted { $0.completedAt > $1.completedAt }
    }

    private func startListeners() {
        guard let clientId = client.id else { return }

        sessionsListener = CoachingSessionService.shared.sessionsListener(userId: clientId) {
            sessions = $0
        }
        assignmentsListener = AssignmentService.shared.assignmentsForClientListener(clientId: clientId) { all in
            assignments = all.filter { $0.coachId == coachId }
        }
        completionsListener = AssignmentService.shared.coachClientCompletionsListener(
            clientId: clientId, coachId: coachId,
            onChange: { completions = $0 }
        )
        goalsListener = GoalService.shared.sharedGoalsListener(clientId: clientId) {
            sharedGoals = $0
        }

        checkNotes()
    }

    private func stopListeners() {
        sessionsListener?.remove()
        assignmentsListener?.remove()
        completionsListener?.remove()
        goalsListener?.remove()
    }

    private func checkNotes() {
        Task {
            let has = await CoachClientNoteService.shared.hasEntries(
                coachId: coachId, clientId: client.id ?? "")
            await MainActor.run { hasNotes = has }
        }
    }
}
