import SwiftUI

struct JournalingDetailView: View {
    let practice: DailyPractice
    let userId: String
    var onCompleted: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var currentQuestion: String = ""
    @State private var journalText = ""
    @State private var completed = false
    @State private var isShuffling = false

    private let accentColor = Color(hex: "7B5EA7")

    private var canComplete: Bool {
        !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text(practice.emoji)
                            .font(.system(size: 44))
                        Text(practice.title)
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("A moment to check in with yourself")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(accentColor.opacity(0.7))
                    }
                    .padding(.top, 36)

                    // ── Question card ──
                    questionCard

                    // ── Text editor ──
                    editorSection

                    // ── Complete / Done ──
                    if completed {
                        doneBanner
                    } else {
                        completeButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear { pickRandomQuestion() }
    }

    // MARK: - Question card

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text(currentQuestion)
                    .font(ContinuoTheme.rounded(17, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.2), value: currentQuestion)

                Spacer(minLength: 12)

                // Shuffle button
                Button(action: shuffleQuestion) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.10))
                            .frame(width: 40, height: 40)
                        Image(systemName: "shuffle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(accentColor)
                            .rotationEffect(.degrees(isShuffling ? 180 : 0))
                            .animation(.easeInOut(duration: 0.25), value: isShuffling)
                    }
                }
                .buttonStyle(.plain)
                .disabled(completed)
            }

            Text("Tap  \(Image(systemName: "shuffle"))  for a different question")
                .font(ContinuoTheme.rounded(11))
                .foregroundColor(ContinuoTheme.textLight)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(accentColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(accentColor.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Editor

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your reflection")
                .font(ContinuoTheme.rounded(14, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            ZStack(alignment: .topLeading) {
                if journalText.isEmpty {
                    Text("Write freely here…")
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.textLight)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $journalText)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .frame(minHeight: 160)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .disabled(completed)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "EDE8E0"), lineWidth: 1.5)
                    )
            )
        }
    }

    // MARK: - Complete button

    private var completeButton: some View {
        Button(action: complete) {
            HStack {
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("Complete  +\(practice.gpReward) GP")
                    .font(ContinuoTheme.rounded(16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(canComplete ? accentColor : ContinuoTheme.textLight)
            )
        }
        .disabled(!canComplete)
        .animation(.easeInOut(duration: 0.2), value: canComplete)
    }

    private var doneBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(accentColor)
                .font(.title3)
            Text("Journal entry saved. Well done.")
                .font(ContinuoTheme.rounded(15, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accentColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.22), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func pickRandomQuestion() {
        currentQuestion = practice.prompts.randomElement() ?? practice.prompts[0]
    }

    private func shuffleQuestion() {
        guard !completed else { return }
        let other = practice.prompts.filter { $0 != currentQuestion }
        let next = other.randomElement() ?? practice.prompts[0]
        isShuffling = true
        withAnimation(.easeInOut(duration: 0.2)) {
            currentQuestion = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShuffling = false
        }
    }

    private func complete() {
        guard canComplete else { return }
        let responses = [currentQuestion, journalText.trimmingCharacters(in: .whitespacesAndNewlines)]
        try? DailyPracticeService.shared.complete(practice: practice, responses: responses, userId: userId)
        withAnimation { completed = true }
        onCompleted?(practice.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}
