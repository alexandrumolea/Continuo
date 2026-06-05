import SwiftUI

struct SendFeedbackFormView: View {
    let coachId: String
    let clientId: String
    let clientName: String

    @State private var selected: Set<String> = []
    @State private var isSending = false
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss

    private var canSend: Bool { !selected.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // Subtitle
                        Text("Select the questions you want to send to \(clientName). They'll appear as a feedback request on their home screen.")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)

                        // Categories
                        ForEach(FeedbackQuestion.categories, id: \.self) { category in
                            categorySection(category)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                // Floating send button
                VStack {
                    Spacer()
                    sendBar
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Send Feedback Form")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay(successOverlay)
        }
    }

    // MARK: - Category section

    private func categorySection(_ category: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category)
                .font(ContinuoTheme.rounded(15, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            VStack(spacing: 1) {
                ForEach(FeedbackQuestion.questions(in: category)) { question in
                    questionRow(question)
                    if question.id != FeedbackQuestion.questions(in: category).last?.id {
                        Divider().padding(.leading, 52).opacity(0.4)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.92))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
            )
            .shadow(color: Color(hex: "2D2926").opacity(0.05), radius: 12, x: 0, y: 3)
        }
    }

    private func questionRow(_ question: FeedbackQuestion) -> some View {
        Button { toggle(question.id) } label: {
            HStack(spacing: 14) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(selected.contains(question.id) ? ContinuoTheme.terracotta : Color(hex: "C4BDB5"), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if selected.contains(question.id) {
                        Circle().fill(ContinuoTheme.terracotta).frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(question.text)
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                // Type badge
                typeBadge(question.type)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(selected.contains(question.id) ? ContinuoTheme.terracotta.opacity(0.04) : Color.clear)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: selected.contains(question.id))
    }

    @ViewBuilder
    private func typeBadge(_ type: FeedbackQuestionType) -> some View {
        switch type {
        case .rating:
            Text("1–10")
                .font(ContinuoTheme.rounded(10, weight: .semibold))
                .foregroundColor(ContinuoTheme.sunYellow)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(ContinuoTheme.sunYellow.opacity(0.12)))
        case .milestone:
            Text("Track")
                .font(ContinuoTheme.rounded(10, weight: .semibold))
                .foregroundColor(Color(hex: "4E7040"))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(Color(hex: "4E7040").opacity(0.12)))
        case .open:
            Text("Open")
                .font(ContinuoTheme.rounded(10, weight: .semibold))
                .foregroundColor(Color(hex: "2E7DD1"))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(Color(hex: "2E7DD1").opacity(0.12)))
        }
    }

    // MARK: - Send bar

    private var sendBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selected.count) question\(selected.count == 1 ? "" : "s") selected")
                        .font(ContinuoTheme.rounded(13, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    if !selected.isEmpty {
                        Text("to \(clientName)")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                }
                Spacer()
                Button { send() } label: {
                    HStack(spacing: 6) {
                        if isSending {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill").font(.system(size: 13))
                            Text("Send").font(ContinuoTheme.rounded(15, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(
                        Capsule().fill(canSend ? ContinuoTheme.terracotta : ContinuoTheme.textLight)
                    )
                }
                .disabled(!canSend || isSending)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Success overlay

    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 14) {
                    Text("✓").font(.system(size: 52))
                    Text("Feedback form sent!")
                        .font(ContinuoTheme.rounded(22, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Text("\(clientName) will see it on their home screen.")
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

    // MARK: - Actions

    private func toggle(_ id: String) {
        HapticFeedback.selection()
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func send() {
        guard canSend else { return }
        isSending = true
        FeedbackService.shared.sendForm(
            coachId: coachId,
            clientId: clientId,
            questionIds: Array(selected)
        )
        HapticFeedback.success()
        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { dismiss() }
    }
}
