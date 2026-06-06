import SwiftUI

/// Allows a coach to edit the responses of a saved Session Reflection entry.
struct CoachPracticeEntryEditView: View {
    let entry: CoachPracticeEntry
    let coachId: String
    let prompts: [String]

    @State private var responses: [String: String]
    @State private var isSaving = false
    @State private var showSuccess = false
    @FocusState private var focused: String?
    @Environment(\.dismiss) private var dismiss

    init(entry: CoachPracticeEntry, coachId: String, prompts: [String]) {
        self.entry   = entry
        self.coachId = coachId
        self.prompts = prompts
        _responses = State(initialValue: entry.responses)
    }

    private var hasChanges: Bool {
        responses != entry.responses
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.practiceEmoji).font(.system(size: 40))
                            Text(entry.practiceTitle)
                                .font(ContinuoTheme.rounded(24, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text(entry.date, style: .date)
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                        .padding(.top, 8)

                        ForEach(prompts, id: \.self) { prompt in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(prompt)
                                    .font(ContinuoTheme.rounded(14, weight: .medium))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .fixedSize(horizontal: false, vertical: true)

                                let binding = Binding(
                                    get: { responses[prompt] ?? "" },
                                    set: { responses[prompt] = $0 }
                                )

                                TextEditor(text: binding)
                                    .font(ContinuoTheme.rounded(14))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .frame(minHeight: 100)
                                    .focused($focused, equals: prompt)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white.opacity(0.85))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(
                                                        focused == prompt
                                                            ? Color(hex: "7B5EA7").opacity(0.6)
                                                            : Color(hex: "EDE8E0"),
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    )
                                    .overlay(
                                        Group {
                                            if binding.wrappedValue.isEmpty {
                                                Text("Write your response here…")
                                                    .font(ContinuoTheme.rounded(14))
                                                    .foregroundColor(ContinuoTheme.textLight)
                                                    .padding(20)
                                                    .allowsHitTesting(false)
                                            }
                                        }, alignment: .topLeading
                                    )
                            }
                        }

                        PrimaryButton(
                            title: isSaving ? "Saving…" : "Save changes",
                            isLoading: isSaving
                        ) { save() }
                        .disabled(!hasChanges || isSaving)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
                .overlay(successOverlay)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 12) {
                    Text("✓").font(.system(size: 48))
                    Text("Saved!")
                        .font(ContinuoTheme.rounded(20, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }

    private func save() {
        isSaving = true
        let trimmed = responses.mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        CoachPracticeService.shared.updateEntry(
            entryId: entry.id,
            coachId: coachId,
            responses: trimmed
        )
        HapticFeedback.success()
        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
    }
}
