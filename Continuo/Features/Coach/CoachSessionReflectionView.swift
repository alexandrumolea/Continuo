import SwiftUI
import FirebaseFirestore

struct CoachSessionReflectionView: View {
    let practice: CoachPractice
    let coachId: String
    let prompts: [String]

    @State private var responses: [String]
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @FocusState private var focusedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    init(practice: CoachPractice, coachId: String, prompts: [String]) {
        self.practice = practice
        self.coachId = coachId
        self.prompts = prompts
        _responses = State(initialValue: Array(repeating: "", count: prompts.count))
    }

    private var canSubmit: Bool {
        responses.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(practice.emoji)
                            .font(.system(size: 44))
                        Text(practice.title)
                            .font(ContinuoTheme.rounded(26, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text(practice.category)
                            .font(ContinuoTheme.rounded(13, weight: .semibold))
                            .foregroundColor(practice.categoryColor)
                    }
                    .padding(.top, 36)

                    // Prompt + response pairs
                    ForEach(Array(prompts.enumerated()), id: \.offset) { idx, prompt in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 6) {
                                Text(prompt)
                                    .font(ContinuoTheme.rounded(15, weight: .medium))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .fixedSize(horizontal: false, vertical: true)
                                if idx > 0 {
                                    Text("optional")
                                        .font(ContinuoTheme.rounded(11))
                                        .foregroundColor(ContinuoTheme.textLight)
                                        .padding(.top, 3)
                                }
                            }

                            TextEditor(text: $responses[idx])
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .frame(minHeight: 110)
                                .focused($focusedIndex, equals: idx)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.85))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    focusedIndex == idx
                                                        ? practice.categoryColor.opacity(0.6)
                                                        : Color(hex: "EDE8E0"),
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                .overlay(
                                    Group {
                                        if responses[idx].isEmpty {
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
                        title: isSubmitting ? "Saving…" : "Save reflection",
                        isLoading: isSubmitting
                    ) { submit() }
                    .disabled(!canSubmit || isSubmitting)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .overlay(successOverlay)
        }
    }

    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 14) {
                    Text("✓")
                        .font(.system(size: 52))
                    Text("Saved!")
                        .font(ContinuoTheme.rounded(22, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        var responsesDict: [String: String] = [:]
        for (idx, prompt) in prompts.enumerated() {
            let text = responses[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { responsesDict[prompt] = text }
        }
        let entry = CoachPracticeEntry(
            id: UUID().uuidString,
            practiceId: practice.id,
            practiceTitle: practice.title,
            practiceEmoji: practice.emoji,
            questionText: nil,
            responses: responsesDict,
            createdAt: Timestamp(date: Date())
        )
        CoachPracticeService.shared.save(entry: entry, coachId: coachId)
        HapticFeedback.success()
        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }
}
