import SwiftUI
import FirebaseFirestore

struct CoachQuestionListView: View {
    let practice: CoachPractice
    let coachId: String
    let questions: [String]

    @State private var completedQuestions: Set<String> = []
    @State private var selectedQuestion: String? = nil
    @State private var questionsListener: ListenerRegistration?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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

                        Text("Tap a question you want to explore.")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)

                        // Question list
                        VStack(spacing: 1) {
                            ForEach(Array(questions.enumerated()), id: \.element) { idx, question in
                                QuestionRow(
                                    question: question,
                                    isSelected: selectedQuestion == question,
                                    isCompleted: completedQuestions.contains(question),
                                    accentColor: practice.categoryColor
                                ) {
                                    HapticFeedback.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedQuestion = selectedQuestion == question ? nil : question
                                    }
                                }

                                if idx < questions.count - 1 {
                                    Divider()
                                        .padding(.leading, 52)
                                        .opacity(0.4)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color(hex: "EDE8E0"), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color(hex: "2D2926").opacity(0.06), radius: 16, x: 0, y: 4)

                        // Inline context form, shown below the list when a question is selected
                        if let question = selectedQuestion {
                            QuestionContextForm(
                                question: question,
                                practice: practice,
                                coachId: coachId,
                                onSaved: {
                                    completedQuestions.insert(question)
                                    withAnimation { selectedQuestion = nil }
                                }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(ContinuoTheme.rounded(16))
                }
            }
            .onAppear {
                questionsListener = CoachPracticeService.shared.completedQuestionsListener(
                    coachId: coachId,
                    practiceId: practice.id
                ) { completedQuestions = $0 }
            }
            .onDisappear { questionsListener?.remove() }
        }
    }
}

// MARK: - Question Row

private struct QuestionRow: View {
    let question: String
    let isSelected: Bool
    let isCompleted: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : (isCompleted ? accentColor : Color(hex: "C4BDB5")), lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Circle().fill(accentColor).frame(width: 26, height: 26)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    } else if isCompleted {
                        Circle().fill(accentColor).frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(question)
                    .font(ContinuoTheme.rounded(14, weight: isSelected ? .semibold : (isCompleted ? .medium : .regular)))
                    .foregroundColor(isCompleted && !isSelected ? ContinuoTheme.charcoal.opacity(0.65) : ContinuoTheme.charcoal)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                isSelected ? accentColor.opacity(0.05) : Color.clear
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Inline context form

private struct QuestionContextForm: View {
    let question: String
    let practice: CoachPractice
    let coachId: String
    let onSaved: () -> Void

    @State private var whyValuable = ""
    @State private var contextWho = ""
    @State private var isSubmitting = false
    @FocusState private var focused: Int?

    private var canSubmit: Bool {
        !whyValuable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contextWho.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Selected question highlighted
            Text(question)
                .font(ContinuoTheme.rounded(15, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(practice.cardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(practice.categoryColor.opacity(0.25), lineWidth: 1)
                        )
                )

            promptField(index: 0,
                        label: "Why is this question valuable to you?",
                        text: $whyValuable)

            promptField(index: 1,
                        label: "In what context or with whom do you want to try it next time?",
                        text: $contextWho)

            PrimaryButton(
                title: isSubmitting ? "Saving…" : "Save",
                isLoading: isSubmitting
            ) { submit() }
            .disabled(!canSubmit || isSubmitting)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(practice.categoryColor.opacity(0.2), lineWidth: 1.5)
                )
        )
        .shadow(color: practice.categoryColor.opacity(0.1), radius: 20, x: 0, y: 6)
    }

    @ViewBuilder
    private func promptField(index: Int, label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(ContinuoTheme.rounded(14, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: text)
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.charcoal)
                .frame(minHeight: 90)
                .focused($focused, equals: index)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    focused == index
                                        ? practice.categoryColor.opacity(0.6)
                                        : Color(hex: "EDE8E0"),
                                    lineWidth: 1.5
                                )
                        )
                )
                .overlay(
                    Group {
                        if text.wrappedValue.isEmpty {
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

    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true
        let entry = CoachPracticeEntry(
            id: UUID().uuidString,
            practiceId: practice.id,
            practiceTitle: practice.title,
            practiceEmoji: practice.emoji,
            questionText: question,
            responses: [
                "Why is this question valuable to you?": whyValuable.trimmingCharacters(in: .whitespacesAndNewlines),
                "In what context or with whom do you want to try it next time?": contextWho.trimmingCharacters(in: .whitespacesAndNewlines)
            ],
            createdAt: Timestamp(date: Date())
        )
        CoachPracticeService.shared.save(entry: entry, coachId: coachId)
        HapticFeedback.success()
        onSaved()
    }
}
