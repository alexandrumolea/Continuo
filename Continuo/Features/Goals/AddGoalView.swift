import SwiftUI

struct AddGoalView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedType: GoalType = .general
    @State private var selectedEmoji: String = "🌱"
    @State private var isSaving = false
    @FocusState private var titleFocused: Bool

    private let emojiOptions = [
        "🌱", "🎯", "💪", "🧠", "⭐", "🔥",
        "🏆", "🌊", "🤝", "❤️", "🌿", "💡",
        "🗺️", "🔑", "🌟", "🧘", "📖", "✍️",
        "🦁", "🌸", "🎨", "🪴", "🌙", "✨"
    ]

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

                // Emoji picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Icon")
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textMedium)
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 10) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                    selectedEmoji = emoji
                                }
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 26))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedEmoji == emoji
                                                  ? selectedType.color.opacity(0.15)
                                                  : Color.white.opacity(0.6))
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedEmoji == emoji
                                                        ? selectedType.color.opacity(0.5)
                                                        : Color(hex: "EDE8E0"), lineWidth: 1.5))
                                    )
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
                        emoji: selectedEmoji, progress: 0, createdAt: Date())
        do {
            try GoalService.shared.addGoal(goal)
            HapticFeedback.success()
            dismiss()
        } catch {
            print("❌ addGoal: \(error)")
            isSaving = false
        }
    }
}
