import SwiftUI

struct GoalReorderSheet: View {
    @Binding var goals: [Goal]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reorder Goals")
                            .font(ContinuoTheme.rounded(22, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("Drag to set your focus order")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(ContinuoTheme.textLight)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                List {
                    ForEach(goals) { goal in
                        HStack(spacing: 14) {
                            Text(goal.emoji ?? goal.type.emoji)
                                .font(.system(size: 26))
                                .frame(width: 36)

                            Text(goal.title)
                                .font(ContinuoTheme.rounded(15, weight: .medium))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .lineLimit(2)

                            Spacer()

                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 16))
                                .foregroundColor(ContinuoTheme.textLight)
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.white.opacity(0.7))
                        .listRowSeparatorTint(Color(hex: "EDE8E0"))
                    }
                    .onMove { from, to in
                        HapticFeedback.selection()
                        goals.move(fromOffsets: from, toOffset: to)
                        Task { try? await GoalService.shared.reorder(goals: goals) }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
        }
    }
}
