import SwiftUI
import FirebaseFirestore

/// Full-page view of a shared goal — shown to the coach.
/// Coach-created goals can be edited here; client-created goals stay read-only.
struct CoachClientGoalDetailView: View {
    let clientName: String

    @State private var goal: Goal
    @State private var reflections: [GoalReflection] = []
    @State private var listener: ListenerRegistration?
    @State private var goalListener: ListenerRegistration?
    @State private var showEdit = false

    init(goal: Goal, clientName: String) {
        self.clientName = clientName
        _goal = State(initialValue: goal)
    }

    private var progressPercent: Int { Int((goal.progress * 100).rounded()) }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    if let measure = goal.successMeasure,
                       !measure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        successMeasureCard(measure)
                    }
                    progressCard
                    reflectionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if goal.isFromCoach {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEdit = true } label: {
                        Text("Edit")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(goal.type.color)
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditClientGoalView(goal: goal)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear { startListener() }
        .onDisappear {
            listener?.remove()
            goalListener?.remove()
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(goal.type.color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Text(goal.emoji ?? goal.type.emoji).font(.title2)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(ContinuoTheme.rounded(18, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(goal.type.label)
                        .font(ContinuoTheme.rounded(11, weight: .semibold))
                        .foregroundColor(goal.type.color)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(goal.type.color.opacity(0.10)))
                }
                Spacer()
            }
        }
    }

    // MARK: - Success measure

    private func successMeasureCard(_ text: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("How success looks", systemImage: "checkmark.seal.fill")
                    .font(ContinuoTheme.rounded(12, weight: .semibold))
                    .foregroundColor(goal.type.color)
                Text(text)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Progress

    private var progressCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Progress")
                        .font(ContinuoTheme.rounded(13, weight: .semibold))
                        .foregroundColor(ContinuoTheme.textMedium)
                    Spacer()
                    Text("\(progressPercent)%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(goal.type.color)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(goal.type.color.opacity(0.12))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(goal.type.color)
                            .frame(width: geo.size.width * goal.progress, height: 10)
                    }
                }
                .frame(height: 10)
            }
        }
    }

    // MARK: - Reflections

    private var reflectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(goal.type.color)
                Text("Reflections")
                    .font(ContinuoTheme.rounded(18, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
            }

            if reflections.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left").font(.caption).foregroundColor(ContinuoTheme.textLight)
                    Text("\(clientName) hasn't added reflections yet.")
                        .font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textLight)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(ContinuoTheme.charcoal.opacity(0.04)))
            } else {
                ForEach(reflections) { reflection in
                    GlassCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(reflection.createdAt, style: .date)
                                    .font(ContinuoTheme.rounded(11, weight: .medium))
                                    .foregroundColor(ContinuoTheme.textLight)
                                Text("·").foregroundColor(ContinuoTheme.textLight)
                                Text(reflection.createdAt, style: .time)
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.textLight)
                            }
                            Text(reflection.text)
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Listener (real-time reflections)

    private func startListener() {
        guard let goalId = goal.id else { return }
        listener = GoalService.shared.reflectionsListener(goalId: goalId) { items in
            reflections = items
        }
        // Keep the goal live so edits appear immediately after saving.
        goalListener = GoalService.shared.goalListener(goalId: goalId) { updated in
            if let updated { goal = updated }
        }
    }
}
