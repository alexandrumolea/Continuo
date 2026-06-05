import SwiftUI

struct FeedbackFormRow: View {
    let form: FeedbackForm
    let response: FeedbackResponse?

    @State private var showResponse = false
    @State private var showDeleteConfirm = false

    private var isCompleted: Bool { response != nil }

    var body: some View {
        Button {
            guard isCompleted else { return }
            showResponse = true
        } label: {
            GlassCard(padding: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isCompleted ? ContinuoTheme.olive.opacity(0.10) : ContinuoTheme.terracotta.opacity(0.08))
                            .frame(width: 40, height: 40)
                        Image(systemName: isCompleted ? "checkmark.bubble.fill" : "bubble.left.and.bubble.right")
                            .font(.system(size: 18))
                            .foregroundColor(isCompleted ? ContinuoTheme.olive : ContinuoTheme.terracotta.opacity(0.6))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(form.questionCount) question\(form.questionCount == 1 ? "" : "s")")
                            .font(ContinuoTheme.rounded(14, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        HStack(spacing: 6) {
                            Text(isCompleted ? "Answered" : "Pending")
                                .font(ContinuoTheme.rounded(12, weight: .semibold))
                                .foregroundColor(isCompleted ? ContinuoTheme.olive : ContinuoTheme.terracotta)
                            Text("·")
                                .foregroundColor(ContinuoTheme.textLight)
                            Text(isCompleted ? (response?.date ?? form.date) : form.date, style: .date)
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                    }

                    Spacer()

                    if isCompleted {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ContinuoTheme.textLight)
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: isCompleted ? 0.97 : 1.0))
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete this feedback form?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                FeedbackService.shared.deleteForm(formId: form.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the form and any response from \(isCompleted ? "your client" : "the queue").")
        }
        .sheet(isPresented: $showResponse) {
            if let response {
                FeedbackResponseDetailView(form: form, response: response)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Coach view of a completed response

struct FeedbackResponseDetailView: View {
    let form: FeedbackForm
    let response: FeedbackResponse

    @Environment(\.dismiss) private var dismiss

    private var questions: [FeedbackQuestion] {
        form.questionIds.compactMap { id in
            FeedbackQuestion.catalog.first { $0.id == id }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("💬").font(.system(size: 40))
                            Text("Feedback from \(response.clientName)")
                                .font(ContinuoTheme.rounded(22, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text(response.date, style: .date)
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                        .padding(.top, 8)

                        // Answers
                        ForEach(questions) { question in
                            if let answer = response.answers.first(where: { $0.questionId == question.id }) {
                                answerCard(question: question, answer: answer)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func answerCard(question: FeedbackQuestion, answer: FeedbackAnswer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.text)
                .font(ContinuoTheme.rounded(13, weight: .semibold))
                .foregroundColor(ContinuoTheme.textMedium)
                .fixedSize(horizontal: false, vertical: true)

            switch question.type {
            case .rating:
                if let rating = answer.ratingValue {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(rating)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(ratingColor(rating))
                        Text("/ 10")
                            .font(ContinuoTheme.rounded(16))
                            .foregroundColor(ContinuoTheme.textLight)
                    }
                    // Mini bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(ratingColor(rating).opacity(0.12)).frame(height: 7)
                            RoundedRectangle(cornerRadius: 4).fill(ratingColor(rating))
                                .frame(width: geo.size.width * CGFloat(rating) / 10.0, height: 7)
                        }
                    }
                    .frame(height: 7)
                }

            case .milestone:
                if let ms = answer.milestoneValue, let milestone = MilestoneValue(rawValue: ms) {
                    HStack(spacing: 8) {
                        Text(milestone.emoji).font(.system(size: 20))
                        Text(milestone.label)
                            .font(ContinuoTheme.rounded(16, weight: .bold))
                            .foregroundColor(milestone.color)
                    }
                }

            case .open:
                if let text = answer.openText, !text.isEmpty {
                    Text(text)
                        .font(ContinuoTheme.rounded(15))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
        )
    }

    private func ratingColor(_ value: Int) -> Color {
        switch value {
        case 1...4:  return Color(hex: "C0392B")
        case 5...6:  return Color(hex: "F5C23A")
        case 7...8:  return Color(hex: "4E7040")
        default:     return Color(hex: "2E7DD1")
        }
    }
}
