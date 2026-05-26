import SwiftUI

struct ReleasingDetailView: View {
    let practice: DailyPractice
    let userId: String
    var onCompleted: ((String) -> Void)? = nil

    @State private var selectedQuestion: String? = nil
    @State private var reflection = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @FocusState private var textFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let color = Color(hex: "2D9B8A")

    private var canSubmit: Bool {
        selectedQuestion != nil &&
        !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text(practice.emoji).font(.system(size: 44))
                        Text(practice.title)
                            .font(ContinuoTheme.rounded(26, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        HStack(spacing: 6) {
                            Text("Daily Practice")
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textMedium)
                            Text("·").foregroundColor(ContinuoTheme.textLight)
                            Text("+\(practice.gpReward) GP")
                                .font(ContinuoTheme.rounded(12, weight: .semibold))
                                .foregroundColor(ContinuoTheme.sunYellow)
                        }
                    }
                    .padding(.top, 36)

                    // ── Question picker ──
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose a question to explore")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)

                        ForEach(practice.prompts, id: \.self) { question in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedQuestion == question {
                                        selectedQuestion = nil
                                        reflection = ""
                                    } else {
                                        selectedQuestion = question
                                        reflection = ""
                                    }
                                }
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    let isSelected = selectedQuestion == question
                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? color : Color.clear)
                                            .frame(width: 22, height: 22)
                                        Circle()
                                            .stroke(isSelected ? color : ContinuoTheme.textLight.opacity(0.5), lineWidth: 1.5)
                                            .frame(width: 22, height: 22)
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    Text(question)
                                        .font(ContinuoTheme.rounded(14))
                                        .foregroundColor(selectedQuestion == question
                                                         ? ContinuoTheme.charcoal
                                                         : ContinuoTheme.textMedium)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedQuestion == question
                                              ? color.opacity(0.08)
                                              : Color.white.opacity(0.5))
                                        .overlay(RoundedRectangle(cornerRadius: 14)
                                            .stroke(selectedQuestion == question
                                                    ? color.opacity(0.4)
                                                    : Color(hex: "EDE8E0"), lineWidth: 1.5))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // ── Reflection (appears after selecting a question) ──
                    if selectedQuestion != nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your reflection")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $reflection)
                                    .font(ContinuoTheme.rounded(14))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .frame(minHeight: 130)
                                    .scrollContentBackground(.hidden)
                                    .focused($textFocused)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white.opacity(0.8))
                                            .overlay(RoundedRectangle(cornerRadius: 14)
                                                .stroke(textFocused ? color.opacity(0.5) : Color(hex: "EDE8E0"),
                                                        lineWidth: 1.5))
                                    )

                                if reflection.isEmpty {
                                    Text("Write your thoughts here…")
                                        .font(ContinuoTheme.rounded(14))
                                        .foregroundColor(ContinuoTheme.textLight)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                        // ── Complete button ──
                        if showSuccess {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Completed! +\(practice.gpReward) GP")
                                    .font(ContinuoTheme.rounded(16, weight: .semibold))
                            }
                            .foregroundColor(color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(color.opacity(0.1)))
                        } else {
                            Button { complete() } label: {
                                Group {
                                    if isSubmitting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Complete +\(practice.gpReward) GP")
                                            .font(ContinuoTheme.rounded(16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16)
                                    .fill(canSubmit ? color : ContinuoTheme.textLight.opacity(0.4)))
                                .foregroundColor(.white)
                            }
                            .disabled(!canSubmit || isSubmitting)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private func complete() {
        guard let question = selectedQuestion else { return }
        let text = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSubmitting = true
        do {
            // Store [selected question, reflection text] as two responses
            try DailyPracticeService.shared.complete(
                practice: practice,
                responses: [question, text],
                userId: userId
            )
            withAnimation { showSuccess = true; isSubmitting = false }
            onCompleted?(practice.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
        } catch {
            print("❌ ReleasingDetailView complete: \(error)")
            isSubmitting = false
        }
    }
}
