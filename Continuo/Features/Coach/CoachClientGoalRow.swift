import SwiftUI

/// Tappable card showing a shared goal — navigates to CoachClientGoalDetailView.
struct CoachClientGoalRow: View {
    let goal: Goal
    let clientName: String

    private var progressPercent: Int { Int((goal.progress * 100).rounded()) }

    var body: some View {
        NavigationLink(destination: CoachClientGoalDetailView(goal: goal, clientName: clientName)) {
            GlassCard {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(goal.type.color.opacity(0.12))
                            .frame(width: 42, height: 42)
                        Text(goal.emoji ?? goal.type.emoji).font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(goal.title)
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

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
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundColor(ContinuoTheme.textLight).padding(.top, 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
