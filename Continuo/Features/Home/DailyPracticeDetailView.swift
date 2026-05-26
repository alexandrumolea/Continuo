import SwiftUI

struct DailyPracticeDetailView: View {
    let practice: DailyPractice
    let userId: String
    var onCompleted: ((String) -> Void)? = nil  // called immediately on success

    @State private var responses: [String]
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @FocusState private var focusedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    init(practice: DailyPractice, userId: String, onCompleted: ((String) -> Void)? = nil) {
        self.practice = practice
        self.userId = userId
        self.onCompleted = onCompleted
        _responses = State(initialValue: Array(repeating: "", count: practice.prompts.count))
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
                        HStack(spacing: 6) {
                            Text("Daily Practice")
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textMedium)
                            Text("·")
                                .foregroundColor(ContinuoTheme.textLight)
                            Text("+\(practice.gpReward) GP")
                                .font(ContinuoTheme.rounded(12, weight: .semibold))
                                .foregroundColor(ContinuoTheme.sunYellow)
                        }
                    }
                    .padding(.top, 36)

                    // Prompt + response pairs
                    ForEach(Array(practice.prompts.enumerated()), id: \.offset) { idx, prompt in
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

                    // Submit button
                    PrimaryButton(
                        title: isSubmitting ? "Saving…" : "Complete · +\(practice.gpReward) GP",
                        isLoading: isSubmitting
                    ) {
                        submit()
                    }
                    .disabled(!canSubmit || isSubmitting)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear { focusedIndex = 0 }
        .overlay(successOverlay)
    }

    // MARK: - Success overlay
    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 14) {
                    Text("✓")
                        .font(.system(size: 52))
                    Text("Done!")
                        .font(ContinuoTheme.rounded(22, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Text("+\(practice.gpReward) GP earned")
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.sunYellow)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }

    // MARK: - Submit
    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true
        let trimmed = responses.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        do {
            try DailyPracticeService.shared.complete(
                practice: practice,
                responses: trimmed,
                userId: userId
            )
            onCompleted?(practice.id)          // update parent immediately
            withAnimation { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
        } catch {
            print("❌ DailyPractice complete: \(error)")
            isSubmitting = false
        }
    }
}
