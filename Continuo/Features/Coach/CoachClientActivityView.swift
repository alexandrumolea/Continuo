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

    // Shared goals
    @State private var sharedGoals: [Goal] = []
    @State private var goalsListener: ListenerRegistration?

    // Notes card
    @State private var hasNotes = false
    @State private var showNotes = false

    // Goals
    @State private var showSendGoal = false

    // Feedback
    @State private var feedbackForms: [FeedbackForm] = []
    @State private var feedbackResponses: [FeedbackResponse] = []
    @State private var feedbackFormsListener: ListenerRegistration?
    @State private var feedbackResponsesListener: ListenerRegistration?
    @State private var showSendFeedback = false

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

                    // ── 3. Goals ──
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "target")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.olive)
                                Text("Goals")
                                    .font(ContinuoTheme.rounded(18, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.charcoal)
                            }
                            Spacer()
                            Button { showSendGoal = true } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                                    Text("Send Goal").font(ContinuoTheme.rounded(12, weight: .semibold))
                                }
                                .foregroundColor(ContinuoTheme.olive)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule()
                                    .fill(ContinuoTheme.olive.opacity(0.10))
                                    .overlay(Capsule().stroke(ContinuoTheme.olive.opacity(0.25), lineWidth: 1)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 8)

                        if sharedGoals.isEmpty {
                            GlassCard {
                                HStack(spacing: 12) {
                                    Text("🎯").font(.system(size: 26))
                                    Text("No goals shared yet. Send one to get started.")
                                        .font(ContinuoTheme.rounded(14))
                                        .foregroundColor(ContinuoTheme.textMedium)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                        } else {
                            ForEach(sharedGoals) { goal in
                                CoachClientGoalRow(goal: goal, clientName: client.displayName)
                            }
                        }
                    }

                    // ── 4. Feedback ──
                    feedbackSection

                    // ── 5. Assignments ──
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
            .onDisappear { checkNotes() }
        }
        .sheet(isPresented: $showSendGoal) {
            SendGoalView(
                coachId: coachId,
                clientId: client.id ?? "",
                clientName: client.displayName
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSendFeedback) {
            SendFeedbackFormView(
                coachId: coachId,
                clientId: client.id ?? "",
                clientName: client.displayName
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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

    // MARK: - Feedback section

    @ViewBuilder
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Feedback")
                    .font(ContinuoTheme.rounded(18, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Spacer()
                HStack(spacing: 8) {
                    // Dashboard link
                    NavigationLink(destination: FeedbackDashboardView(coachId: coachId)) {
                        HStack(spacing: 5) {
                            Image(systemName: "chart.bar.fill").font(.system(size: 12, weight: .bold))
                            Text("Dashboard").font(ContinuoTheme.rounded(12, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "2E7DD1"))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule()
                            .fill(Color(hex: "2E7DD1").opacity(0.10))
                            .overlay(Capsule().stroke(Color(hex: "2E7DD1").opacity(0.2), lineWidth: 1)))
                    }
                    .buttonStyle(.plain)

                    // Send new form button
                    Button { showSendFeedback = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                            Text("Send Form").font(ContinuoTheme.rounded(12, weight: .semibold))
                        }
                        .foregroundColor(ContinuoTheme.terracotta)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule()
                            .fill(ContinuoTheme.terracotta.opacity(0.10))
                            .overlay(Capsule().stroke(ContinuoTheme.terracotta.opacity(0.2), lineWidth: 1)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)

            if feedbackForms.isEmpty {
                GlassCard {
                    HStack(spacing: 12) {
                        Text("💬").font(.system(size: 28))
                        Text("No feedback forms sent yet.")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            } else {
                ForEach(feedbackForms) { form in
                    let response = feedbackResponses.first { $0.formId == form.id }
                    FeedbackFormRow(form: form, response: response)
                }
            }
        }
    }

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

        feedbackFormsListener = FeedbackService.shared.sentFormsListener(
            coachId: coachId, clientId: clientId
        ) { feedbackForms = $0 }
        feedbackResponsesListener = FeedbackService.shared.responsesListener(
            coachId: coachId, clientId: clientId
        ) { feedbackResponses = $0 }

        checkNotes()
    }

    private func stopListeners() {
        sessionsListener?.remove()
        assignmentsListener?.remove()
        completionsListener?.remove()
        goalsListener?.remove()
        feedbackFormsListener?.remove()
        feedbackResponsesListener?.remove()
    }

    private func checkNotes() {
        Task {
            let has = await CoachClientNoteService.shared.hasEntries(
                coachId: coachId, clientId: client.id ?? "")
            await MainActor.run { hasNotes = has }
        }
    }
}
