import SwiftUI

struct AddGoalView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedType: GoalType = .general
    @State private var isSaving = false
    @FocusState private var titleFocused: Bool

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Goal")
                        .font(ContinuoTheme.rounded(24, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Text("What do you want to focus on?")
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.textMedium)
                }
                .padding(.top, 8)

                // Type picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Type")
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textMedium)

                    HStack(spacing: 10) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { selectedType = type }
                            } label: {
                                HStack(spacing: 8) {
                                    Text(type.emoji)
                                    Text(type.label)
                                        .font(ContinuoTheme.rounded(14, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedType == type
                                          ? type.color.opacity(0.12)
                                          : Color.clear))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(selectedType == type
                                            ? type.color
                                            : ContinuoTheme.textLight.opacity(0.5),
                                            lineWidth: 1.5))
                                .foregroundColor(selectedType == type
                                                 ? type.color
                                                 : ContinuoTheme.textMedium)
                            }
                        }
                    }
                }

                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal")
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textMedium)
                    AuthField(icon: "flag.fill", placeholder: "e.g. Run a 5K by June…", text: $title)
                        .focused($titleFocused)
                }

                Spacer()

                PrimaryButton(title: isSaving ? "Saving…" : "Add Goal", isLoading: isSaving) {
                    save()
                }
                .disabled(!canSave || isSaving)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDragIndicator(.visible)
        .onAppear { titleFocused = true }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        let goal = Goal(userId: userId, title: trimmed, type: selectedType,
                        progress: 0, createdAt: Date())
        do {
            try GoalService.shared.addGoal(goal)
            dismiss()
        } catch {
            print("❌ addGoal: \(error)")
            isSaving = false
        }
    }
}
