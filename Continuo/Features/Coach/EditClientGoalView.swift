import SwiftUI

/// Lets the coach edit a goal they previously sent to a client.
struct EditClientGoalView: View {
    let goal: Goal

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var selectedType: GoalType
    @State private var selectedEmoji: String
    @State private var successMeasure: String
    @State private var isSaving = false
    @FocusState private var titleFocused: Bool

    private let emojiOptions = [
        "🌱", "🎯", "💪", "🧠", "⭐", "🔥",
        "🏆", "🌊", "🤝", "❤️", "🌿", "💡",
        "🗺️", "🔑", "🌟", "🧘", "📖", "✍️",
        "🦁", "🌸", "🎨", "🪴", "🌙", "✨"
    ]

    init(goal: Goal) {
        self.goal = goal
        _title = State(initialValue: goal.title)
        _selectedType = State(initialValue: goal.type)
        _selectedEmoji = State(initialValue: goal.emoji ?? goal.type.emoji)
        _successMeasure = State(initialValue: goal.successMeasure ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Goal")
                                .font(ContinuoTheme.rounded(24, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("Changes are visible to the client right away.")
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                        .padding(.top, 8)

                        // ── Title ──
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goal")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                            AuthField(
                                icon: "flag.fill",
                                placeholder: "e.g. Improve public speaking by Q3…",
                                text: $title
                            )
                            .focused($titleFocused)
                        }

                        // ── Type ──
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Type")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                            HStack(spacing: 12) {
                                ForEach(GoalType.allCases, id: \.self) { type in
                                    Button {
                                        HapticFeedback.selection()
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            selectedType = type
                                            if selectedEmoji == GoalType.general.emoji || selectedEmoji == GoalType.competence.emoji {
                                                selectedEmoji = type.emoji
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(type.emoji).font(.system(size: 16))
                                            Text(type.label).font(ContinuoTheme.rounded(14, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedType == type
                                                      ? type.color.opacity(0.12) : Color.white.opacity(0.6))
                                                .overlay(RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedType == type
                                                            ? type.color.opacity(0.5) : Color(hex: "EDE8E0"),
                                                            lineWidth: 1.5))
                                        )
                                        .foregroundColor(selectedType == type ? type.color : ContinuoTheme.textMedium)
                                    }
                                }
                            }
                        }

                        // ── Emoji picker ──
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
                                                          ? selectedType.color.opacity(0.15) : Color.white.opacity(0.6))
                                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedEmoji == emoji
                                                                ? selectedType.color.opacity(0.5) : Color(hex: "EDE8E0"),
                                                                lineWidth: 1.5))
                                            )
                                    }
                                }
                            }
                        }

                        // ── Success measure (optional) ──
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("How will we measure success?")
                                    .font(ContinuoTheme.rounded(13))
                                    .foregroundColor(ContinuoTheme.textMedium)
                                Text("optional")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.textLight)
                            }
                            TextEditor(text: $successMeasure)
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.85))
                                        .overlay(RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "EDE8E0"), lineWidth: 1.5))
                                )
                                .overlay(
                                    Group {
                                        if successMeasure.isEmpty {
                                            Text("e.g. Can lead a 30-min team presentation confidently…")
                                                .font(ContinuoTheme.rounded(14))
                                                .foregroundColor(ContinuoTheme.textLight)
                                                .padding(20)
                                                .allowsHitTesting(false)
                                        }
                                    }, alignment: .topLeading
                                )
                        }

                        PrimaryButton(title: isSaving ? "Saving…" : "Save Changes", isLoading: isSaving) {
                            save()
                        }
                        .disabled(!canSave || isSaving)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        let sm = successMeasure.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await GoalService.shared.updateGoalDetails(
                    goal,
                    title: trimmed,
                    type: selectedType,
                    emoji: selectedEmoji,
                    successMeasure: sm.isEmpty ? nil : sm
                )
                await MainActor.run {
                    HapticFeedback.success()
                    dismiss()
                }
            } catch {
                print("❌ EditClientGoalView save: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }
}
