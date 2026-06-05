import SwiftUI
import FirebaseFirestore

// MARK: - Randomizer router

struct CoachQuestionListView: View {
    let practice: CoachPractice
    let coachId: String

    var body: some View {
        switch practice.type {
        case .questionRandomizer(let questions):
            QuestionRandomizerView(practice: practice, coachId: coachId, questions: questions)
        case .categoryRandomizer(let categories):
            CategoryRandomizerView(practice: practice, coachId: coachId, categories: categories)
        case .reflectionForm:
            EmptyView() // handled by CoachSessionReflectionView
        }
    }
}

// MARK: - Single-question randomizer

private struct QuestionRandomizerView: View {
    let practice: CoachPractice
    let coachId: String
    let questions: [String]

    @State private var currentQuestion: String
    @State private var isShuffling = false
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss

    init(practice: CoachPractice, coachId: String, questions: [String]) {
        self.practice = practice
        self.coachId = coachId
        self.questions = questions
        _currentQuestion = State(initialValue: questions.randomElement() ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // Header
                        header

                        // Instructional message
                        Text("Choose the question you'd like to use more frequently in your upcoming sessions.")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)
                            .fixedSize(horizontal: false, vertical: true)

                        // Question card + shuffle
                        VStack(alignment: .leading, spacing: 14) {
                            Text(currentQuestion)
                                .font(ContinuoTheme.rounded(20, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(22)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(practice.cardColor)
                                        .overlay(RoundedRectangle(cornerRadius: 18)
                                            .stroke(practice.categoryColor.opacity(0.3), lineWidth: 1.5))
                                )
                                .opacity(isShuffling ? 0 : 1)
                                .animation(.easeInOut(duration: 0.15), value: isShuffling)

                            shuffleButton
                        }

                        // Highlight button
                        PrimaryButton(title: "Highlight this question") { highlight() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 48)
                }
                .overlay(successOverlay)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.font(ContinuoTheme.rounded(16))
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(practice.emoji).font(.system(size: 44))
            Text(practice.title)
                .font(ContinuoTheme.rounded(26, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)
            Text(practice.category)
                .font(ContinuoTheme.rounded(13, weight: .semibold))
                .foregroundColor(practice.categoryColor)
        }
    }

    private var shuffleButton: some View {
        Button { shuffle() } label: {
            HStack(spacing: 8) {
                Image(systemName: "shuffle").font(.system(size: 13, weight: .semibold))
                Text("Try another question").font(ContinuoTheme.rounded(14, weight: .semibold))
            }
            .foregroundColor(practice.categoryColor)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Capsule()
                .fill(practice.categoryColor.opacity(0.10))
                .overlay(Capsule().stroke(practice.categoryColor.opacity(0.2), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 14) {
                    Text("✓").font(.system(size: 52))
                    Text("Highlighted!")
                        .font(ContinuoTheme.rounded(22, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Text("Added to your practice timeline.")
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.textMedium)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }

    private func shuffle() {
        HapticFeedback.selection()
        withAnimation { isShuffling = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            var next = questions.randomElement() ?? currentQuestion
            if questions.count > 1 { while next == currentQuestion { next = questions.randomElement()! } }
            currentQuestion = next
            withAnimation { isShuffling = false }
        }
    }

    private func highlight() {
        let entry = CoachPracticeEntry(
            id: UUID().uuidString,
            practiceId: practice.id,
            practiceTitle: practice.title,
            practiceEmoji: practice.emoji,
            questionText: currentQuestion,
            categoryQuestions: nil,
            responses: [:],
            createdAt: Timestamp(date: Date())
        )
        CoachPracticeService.shared.save(entry: entry, coachId: coachId)
        HapticFeedback.success()
        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }
}

// MARK: - Category randomizer (Perspective Change)

private struct CategoryRandomizerView: View {
    let practice: CoachPractice
    let coachId: String
    let categories: [CoachQuestionCategory]

    @State private var currentCategory: CoachQuestionCategory
    @State private var isShuffling = false
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss

    init(practice: CoachPractice, coachId: String, categories: [CoachQuestionCategory]) {
        self.practice = practice
        self.coachId = coachId
        self.categories = categories
        _currentCategory = State(initialValue: categories.randomElement()!)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(practice.emoji).font(.system(size: 44))
                            Text(practice.title)
                                .font(ContinuoTheme.rounded(26, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text(practice.category)
                                .font(ContinuoTheme.rounded(13, weight: .semibold))
                                .foregroundColor(practice.categoryColor)
                        }

                        // Instructional message
                        Text("Choose the category of questions you'd like to explore more in your upcoming sessions.")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)
                            .fixedSize(horizontal: false, vertical: true)

                        // Category card + shuffle
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 14) {
                                // Category name
                                Text(currentCategory.name)
                                    .font(ContinuoTheme.rounded(19, weight: .bold))
                                    .foregroundColor(practice.categoryColor)

                                Divider().opacity(0.35)

                                // Questions list
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(currentCategory.questions.indices, id: \.self) { idx in
                                        HStack(alignment: .top, spacing: 10) {
                                            Text("·")
                                                .font(ContinuoTheme.rounded(16, weight: .bold))
                                                .foregroundColor(practice.categoryColor.opacity(0.5))
                                            Text(currentCategory.questions[idx])
                                                .font(ContinuoTheme.rounded(14))
                                                .foregroundColor(ContinuoTheme.charcoal)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(practice.cardColor)
                                    .overlay(RoundedRectangle(cornerRadius: 18)
                                        .stroke(practice.categoryColor.opacity(0.3), lineWidth: 1.5))
                            )
                            .opacity(isShuffling ? 0 : 1)
                            .animation(.easeInOut(duration: 0.15), value: isShuffling)

                            // Shuffle
                            Button { shuffle() } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "shuffle").font(.system(size: 13, weight: .semibold))
                                    Text("Try another category").font(ContinuoTheme.rounded(14, weight: .semibold))
                                }
                                .foregroundColor(practice.categoryColor)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Capsule()
                                    .fill(practice.categoryColor.opacity(0.10))
                                    .overlay(Capsule().stroke(practice.categoryColor.opacity(0.2), lineWidth: 1)))
                            }
                            .buttonStyle(.plain)
                        }

                        // Highlight button
                        PrimaryButton(title: "Highlight this category") { highlight() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 48)
                }
                .overlay(successOverlay)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.font(ContinuoTheme.rounded(16))
                }
            }
        }
    }

    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 14) {
                    Text("✓").font(.system(size: 52))
                    Text("Highlighted!")
                        .font(ContinuoTheme.rounded(22, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Text("Added to your practice timeline.")
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.textMedium)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }

    private func shuffle() {
        HapticFeedback.selection()
        withAnimation { isShuffling = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            var next = categories.randomElement()!
            if categories.count > 1 { while next.id == currentCategory.id { next = categories.randomElement()! } }
            currentCategory = next
            withAnimation { isShuffling = false }
        }
    }

    private func highlight() {
        let entry = CoachPracticeEntry(
            id: UUID().uuidString,
            practiceId: practice.id,
            practiceTitle: practice.title,
            practiceEmoji: practice.emoji,
            questionText: currentCategory.name,
            categoryQuestions: currentCategory.questions,
            responses: [:],
            createdAt: Timestamp(date: Date())
        )
        CoachPracticeService.shared.save(entry: entry, coachId: coachId)
        HapticFeedback.success()
        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }
}
