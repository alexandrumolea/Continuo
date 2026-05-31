import SwiftUI
import FirebaseFirestore

/// Read-only expandable card showing a goal a client has shared with their coach.
struct CoachClientGoalRow: View {
    let goal: Goal
    let clientName: String

    @State private var isExpanded = false
    @State private var reflections: [GoalReflection] = []
    @State private var isLoadingReflections = false

    private var progressPercent: Int { Int((goal.progress * 100).rounded()) }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header row ──
                Button {
                    HapticFeedback.selection()
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                    if isExpanded && reflections.isEmpty { Task { await loadReflections() } }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        // Emoji + type color
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(goal.type.color.opacity(0.12))
                                .frame(width: 42, height: 42)
                            Text(goal.emoji ?? goal.type.emoji)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text(goal.title)
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            // Progress bar + percent inline
                            HStack(spacing: 8) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(goal.type.color.opacity(0.12))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(goal.type.color)
                                            .frame(width: geo.size.width * goal.progress, height: 6)
                                    }
                                }
                                .frame(height: 6)

                                Text("\(progressPercent)%")
                                    .font(ContinuoTheme.rounded(11, weight: .semibold))
                                    .foregroundColor(goal.type.color)
                                    .frame(minWidth: 32, alignment: .trailing)
                            }

                            Text(goal.type.label)
                                .font(ContinuoTheme.rounded(10, weight: .semibold))
                                .foregroundColor(goal.type.color)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Capsule().fill(goal.type.color.opacity(0.10)))
                        }

                        Spacer(minLength: 4)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(ContinuoTheme.textLight)
                            .padding(.top, 2)
                    }
                }
                .buttonStyle(.plain)

                // ── Expanded detail ──
                if isExpanded {
                    Divider().opacity(0.3).padding(.vertical, 12)

                    VStack(alignment: .leading, spacing: 14) {

                        // Success measure
                        if let measure = goal.successMeasure,
                           !measure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Success measure", systemImage: "checkmark.seal")
                                    .font(ContinuoTheme.rounded(11, weight: .semibold))
                                    .foregroundColor(goal.type.color)
                                Text(measure)
                                    .font(ContinuoTheme.rounded(13))
                                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.85))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(goal.type.color.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(goal.type.color.opacity(0.15), lineWidth: 1)))
                        }

                        // Reflections
                        if isLoadingReflections {
                            HStack {
                                Spacer()
                                ProgressView().padding(.vertical, 8)
                                Spacer()
                            }
                        } else if reflections.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "text.bubble")
                                    .font(.caption)
                                    .foregroundColor(ContinuoTheme.textLight)
                                Text("\(clientName) hasn't added reflections yet.")
                                    .font(ContinuoTheme.rounded(12))
                                    .foregroundColor(ContinuoTheme.textLight)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Reflections", systemImage: "text.bubble")
                                    .font(ContinuoTheme.rounded(11, weight: .semibold))
                                    .foregroundColor(goal.type.color)
                                    .padding(.bottom, 4)

                                ForEach(reflections) { reflection in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(reflection.createdAt, style: .date)
                                            .font(ContinuoTheme.rounded(10, weight: .medium))
                                            .foregroundColor(ContinuoTheme.textLight)
                                        Text(reflection.text)
                                            .font(ContinuoTheme.rounded(13))
                                            .foregroundColor(ContinuoTheme.charcoal.opacity(0.85))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: 10)
                                        .fill(ContinuoTheme.charcoal.opacity(0.04)))
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded && reflections.isEmpty {
                Task { await loadReflections() }
            }
        }
    }

    private func loadReflections() async {
        guard let goalId = goal.id else { return }
        isLoadingReflections = true
        reflections = await GoalService.shared.reflectionsOnce(goalId: goalId)
        isLoadingReflections = false
    }
}
