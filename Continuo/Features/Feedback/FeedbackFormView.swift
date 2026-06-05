import SwiftUI

struct FeedbackFormView: View {
    let form: FeedbackForm
    let clientName: String
    let userId: String

    @State private var answers: [String: FeedbackAnswer] = [:]   // questionId → answer
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss

    private var questions: [FeedbackQuestion] {
        form.questionIds.compactMap { id in
            FeedbackQuestion.catalog.first { $0.id == id }
        }
    }

    private var canSubmit: Bool {
        questions.contains { q in
            let a = answers[q.id]
            switch q.type {
            case .rating:    return a?.ratingValue != nil
            case .milestone: return a?.milestoneValue != nil
            case .open:      return !(a?.openText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            }
        }
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("💬").font(.system(size: 44))
                        Text("Coach asked for feedback.")
                            .font(ContinuoTheme.rounded(24, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("\(questions.count) question\(questions.count == 1 ? "" : "s")")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                    .padding(.top, 8)

                    // Questions
                    ForEach(questions) { question in
                        questionCard(question)
                    }

                    // Submit
                    PrimaryButton(
                        title: isSubmitting ? "Sending…" : "Send feedback",
                        isLoading: isSubmitting
                    ) { submit() }
                    .disabled(!canSubmit || isSubmitting)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .overlay(successOverlay)
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Question card

    @ViewBuilder
    private func questionCard(_ question: FeedbackQuestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.text)
                .font(ContinuoTheme.rounded(15, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)

            switch question.type {
            case .rating:
                RatingSelector(
                    value: Binding(
                        get: { answers[question.id]?.ratingValue },
                        set: { answers[question.id] = FeedbackAnswer(questionId: question.id, ratingValue: $0) }
                    )
                )
            case .milestone:
                MilestoneSelector(
                    value: Binding(
                        get: { answers[question.id]?.milestoneValue.flatMap(MilestoneValue.init) },
                        set: { answers[question.id] = FeedbackAnswer(questionId: question.id, milestoneValue: $0?.rawValue) }
                    )
                )
            case .open:
                OpenTextEditor(
                    text: Binding(
                        get: { answers[question.id]?.openText ?? "" },
                        set: { answers[question.id] = FeedbackAnswer(questionId: question.id, openText: $0) }
                    )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
        )
        .shadow(color: Color(hex: "2D2926").opacity(0.05), radius: 12, x: 0, y: 3)
    }

    // MARK: - Success overlay

    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 14) {
                    Text("✓").font(.system(size: 52))
                    Text("Feedback sent!")
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

    // MARK: - Submit

    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true
        let answersArray = Array(answers.values)
        FeedbackService.shared.submitResponse(
            form: form,
            clientName: clientName,
            answers: answersArray
        )
        HapticFeedback.success()
        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }
}

// MARK: - Rating selector (1–10)

private struct RatingSelector: View {
    @Binding var value: Int?

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { n in
                    Button {
                        HapticFeedback.selection()
                        value = (value == n) ? nil : n
                    } label: {
                        ZStack {
                            Circle()
                                .fill(value == n ? ContinuoTheme.sunYellow : ContinuoTheme.charcoal.opacity(0.07))
                                .overlay(Circle().stroke(
                                    value == n ? ContinuoTheme.sunYellow : Color(hex: "C4BDB5"),
                                    lineWidth: 1))
                            Text("\(n)")
                                .font(ContinuoTheme.rounded(12, weight: value == n ? .bold : .regular))
                                .foregroundColor(value == n ? .white : ContinuoTheme.charcoal.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.1), value: value)
                }
            }
            HStack {
                Text("Low").font(ContinuoTheme.rounded(10)).foregroundColor(ContinuoTheme.textLight)
                Spacer()
                Text("High").font(ContinuoTheme.rounded(10)).foregroundColor(ContinuoTheme.textLight)
            }
        }
    }
}

// MARK: - Milestone selector

private struct MilestoneSelector: View {
    @Binding var value: MilestoneValue?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(MilestoneValue.allCases, id: \.rawValue) { milestone in
                Button {
                    HapticFeedback.selection()
                    value = (value == milestone) ? nil : milestone
                } label: {
                    HStack(spacing: 6) {
                        Text(milestone.emoji).font(.system(size: 14))
                        Text(milestone.label)
                            .font(ContinuoTheme.rounded(13, weight: .semibold))
                    }
                    .foregroundColor(value == milestone ? .white : milestone.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(value == milestone ? milestone.color : milestone.color.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(milestone.color.opacity(0.3), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.12), value: value)
            }
        }
    }
}

// MARK: - Open text editor

private struct OpenTextEditor: View {
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        TextEditor(text: $text)
            .font(ContinuoTheme.rounded(14))
            .foregroundColor(ContinuoTheme.charcoal)
            .frame(minHeight: 100)
            .focused($focused)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(focused ? ContinuoTheme.terracotta.opacity(0.5) : Color(hex: "EDE8E0"), lineWidth: 1.5))
            )
            .overlay(
                Group {
                    if text.isEmpty {
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
