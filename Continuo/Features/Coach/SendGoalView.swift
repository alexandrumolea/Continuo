import SwiftUI

struct SendGoalView: View {
    let coachId: String
    let clientId: String
    let clientName: String

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedType: GoalType = .general
    @State private var selectedEmoji: String = "🌱"
    @State private var successMeasure = ""
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
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Send a Goal")
                                .font(ContinuoTheme.rounded(24, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("This goal will appear in \(clientName)'s focus list.")
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                        .padding(.top, 8)

                        // ── Title ──────────────────────────────────────────
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

                        // ── Type ───────────────────────────────────────────
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

                        // ── Emoji picker ───────────────────────────────────
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

                        // ── Success measure (optional) ─────────────────────
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

                        PrimaryButton(title: isSaving ? "Sending…" : "Send to \(clientName)", isLoading: isSaving) {
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
            .onAppear { titleFocused = true }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        let sm = successMeasure.trimmingCharacters(in: .whitespacesAndNewlines)
        var goal = Goal(
            userId: clientId,
            title: trimmed,
            type: selectedType,
            emoji: selectedEmoji,
            progress: 0,
            createdAt: Date(),
            successMeasure: sm.isEmpty ? nil : sm
        )
        goal.sharedWithCoach = true
        goal.createdByCoach  = true
        goal.coachId         = coachId
        do {
            try GoalService.shared.addGoalForClient(goal)
            HapticFeedback.success()
            dismiss()
        } catch {
            print("❌ SendGoalView save: \(error)")
            isSaving = false
        }
    }
}
