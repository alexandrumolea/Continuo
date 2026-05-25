import SwiftUI
import FirebaseFirestore

struct AssignmentDetailView: View {
    let assignment: Assignment
    let userId: String

    @State private var responseText = ""
    @State private var completions: [AssignmentCompletion] = []
    @State private var showFinishAlert = false
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var expandedId: String? = nil
    @State private var replyDraft = ""
    @State private var editingMsg: ThreadMessage? = nil
    @State private var editMsgDraft = ""
    @FocusState private var textFocused: Bool
    @FocusState private var replyFocused: Bool
    @FocusState private var editMsgFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let service = AssignmentService.shared

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    if assignment.isDueNow || completions.isEmpty {
                        responseCard
                    }
                    if !completions.isEmpty {
                        historySection
                    }
                    if assignment.status == .active && !completions.isEmpty {
                        finishButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle(assignment.type.label)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mark as Finished?", isPresented: $showFinishAlert) {
            Button("Finish", role: .destructive) { markFinished() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This challenge will move to your Growth achievements. You won't be able to complete it again.")
        }
        .overlay(successOverlay)
        .onAppear { loadCompletions() }
    }

    // MARK: - Header card
    private var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(assignment.type.emoji)
                        .font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(assignment.title)
                            .font(ContinuoTheme.rounded(18, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        HStack(spacing: 8) {
                            Label(assignment.recurrence.label, systemImage: assignment.recurrence.icon)
                                .font(ContinuoTheme.rounded(11, weight: .medium))
                                .foregroundColor(assignment.type.color)
                            if assignment.completionCount > 0 {
                                Text("·")
                                Text("\(assignment.completionCount)× completed")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.textMedium)
                            }
                        }
                    }
                }

                if !assignment.description.isEmpty {
                    Text(assignment.description)
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.textMedium)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Label("+\(assignment.gpReward) GP per completion", systemImage: "star.fill")
                        .font(ContinuoTheme.rounded(12, weight: .semibold))
                        .foregroundColor(ContinuoTheme.sunYellow)
                    Spacer()
                    if let exp = assignment.expiresAt {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(exp, style: .date)
                        }
                        .font(ContinuoTheme.rounded(11))
                        .foregroundColor(ContinuoTheme.textLight)
                    }
                }
            }
        }
    }

    // MARK: - Response card
    private var responseCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(assignment.isDueNow || completions.isEmpty ? "Your response" : "Completed today ✓")
                    .font(ContinuoTheme.rounded(15, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)

                if assignment.type.needsTextResponse {
                    TextEditor(text: $responseText)
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .frame(minHeight: 120)
                        .focused($textFocused)
                        .scrollContentBackground(.hidden)
                        .background(Color(hex: "F5F2EC").opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Group {
                                if responseText.isEmpty {
                                    Text("Write your reflection here…")
                                        .font(ContinuoTheme.rounded(14))
                                        .foregroundColor(ContinuoTheme.textLight)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }

                PrimaryButton(title: isSubmitting ? "Saving…" : "Mark as Complete",
                              isLoading: isSubmitting) {
                    submitCompletion()
                }
                .disabled(assignment.type.needsTextResponse && responseText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - History
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your history")
                .font(ContinuoTheme.rounded(18, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            ForEach(completions) { completion in
                completionCard(completion)
            }
        }
    }

    private func completionCard(_ completion: AssignmentCompletion) -> some View {
        let isExpanded = expandedId == completion.id
        let thread = resolvedThread(completion)
        let coachHasReplied = !thread.isEmpty

        return GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {

                // ── Header ──
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ContinuoTheme.olive)
                    Text(completion.completedAt, style: .date)
                        .font(ContinuoTheme.rounded(12, weight: .medium))
                        .foregroundColor(ContinuoTheme.textMedium)
                    Spacer()
                    if completion.isLiked {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.subheadline)
                    }
                    Text(completion.completedAt, style: .time)
                        .font(ContinuoTheme.rounded(11))
                        .foregroundColor(ContinuoTheme.textLight)
                }

                // ── Client original response ──
                if !completion.response.isEmpty {
                    Text(completion.response)
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "F5F2EC").opacity(0.8)))
                }

                // ── Conversation thread ──
                if !thread.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(thread) { msg in
                            messageBubble(msg, completion: completion)
                        }
                    }
                }

                // ── Reply input or button (only after coach has replied) ──
                if coachHasReplied {
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .bottom, spacing: 8) {
                                TextField("Your reply…", text: $replyDraft, axis: .vertical)
                                    .font(ContinuoTheme.rounded(13))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .focused($replyFocused)
                                    .lineLimit(1...5)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.9))
                                            .overlay(RoundedRectangle(cornerRadius: 10)
                                                .stroke(ContinuoTheme.olive.opacity(0.4), lineWidth: 1.5))
                                    )

                                Button { sendClientReply(to: completion) } label: {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Circle().fill(
                                            replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                ? ContinuoTheme.textLight
                                                : ContinuoTheme.olive
                                        ))
                                }
                                .disabled(replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            Button {
                                expandedId = nil
                                replyDraft = ""
                                replyFocused = false
                            } label: {
                                Text("Cancel")
                                    .font(ContinuoTheme.rounded(12))
                                    .foregroundColor(ContinuoTheme.textLight)
                            }
                        }
                    } else {
                        Button {
                            replyDraft = ""
                            expandedId = completion.id
                            replyFocused = true
                        } label: {
                            Label("Reply to coach", systemImage: "arrowshape.turn.up.left")
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                    }
                }
            }
        }
    }

    private func messageBubble(_ msg: ThreadMessage, completion: AssignmentCompletion) -> some View {
        let isCoach = msg.role == "coach"
        let color: Color = isCoach ? ContinuoTheme.terracotta : ContinuoTheme.olive
        let label = isCoach ? "Coach" : "You"
        let icon = isCoach ? "person.circle.fill" : "arrowshape.turn.up.left.fill"
        let isEditing = editingMsg?.id == msg.id

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(ContinuoTheme.rounded(10, weight: .semibold))
                        .foregroundColor(color)
                    if !isEditing {
                        Text(msg.text)
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                // Edit option only for client's own messages
                if !isCoach && !isEditing {
                    Menu {
                        Button {
                            editMsgDraft = msg.text
                            editingMsg = msg
                            editMsgFocused = true
                        } label: { Label("Edit", systemImage: "pencil") }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(ContinuoTheme.textLight)
                            .padding(6)
                    }
                }
            }

            // Inline edit field
            if isEditing {
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Edit message…", text: $editMsgDraft, axis: .vertical)
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .focused($editMsgFocused)
                        .lineLimit(1...5)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.9))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(color.opacity(0.4), lineWidth: 1.5)))

                    Button {
                        let text = editMsgDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        Task { try? await AssignmentService.shared.editMessage(completion: completion, messageId: msg.id, newText: text) }
                        editingMsg = nil
                        editMsgFocused = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(editMsgDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ContinuoTheme.textLight : color)
                    }
                    .disabled(editMsgDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Button {
                    editingMsg = nil
                    editMsgFocused = false
                } label: {
                    Text("Cancel")
                        .font(ContinuoTheme.rounded(11))
                        .foregroundColor(ContinuoTheme.textLight)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.07)))
    }

    private func resolvedThread(_ completion: AssignmentCompletion) -> [ThreadMessage] {
        if !completion.messages.isEmpty {
            return completion.messages.sorted { $0.date < $1.date }
        }
        var legacy: [ThreadMessage] = []
        if let cr = completion.coachReply, !cr.isEmpty {
            legacy.append(ThreadMessage(id: "legacy_coach", role: "coach", text: cr,
                                        sentAt: Timestamp(date: completion.completedAt)))
        }
        if let cl = completion.clientReply, !cl.isEmpty {
            legacy.append(ThreadMessage(id: "legacy_client", role: "client", text: cl,
                                        sentAt: Timestamp(date: completion.completedAt)))
        }
        return legacy
    }

    private func sendClientReply(to completion: AssignmentCompletion) {
        let text = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let id = completion.id else { return }
        Task { try? await AssignmentService.shared.appendMessage(completionId: id, role: "client", text: text) }
        expandedId = nil
        replyDraft = ""
        replyFocused = false
    }

    // MARK: - Finish button
    private var finishButton: some View {
        Button {
            showFinishAlert = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                Text("Mark Challenge as Finished")
                    .font(ContinuoTheme.rounded(15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(ContinuoTheme.sunYellow.opacity(0.15)))
            .foregroundColor(ContinuoTheme.terracotta)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ContinuoTheme.sunYellow.opacity(0.4), lineWidth: 1.5))
        }
    }

    // MARK: - Success overlay
    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 12) {
                    Text("✓").font(.system(size: 52))
                    Text("Completed!").font(ContinuoTheme.rounded(20, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Text("+\(assignment.gpReward) GP earned")
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

    // MARK: - Actions
    private func loadCompletions() {
        _ = service.completionsListener(assignmentId: assignment.id ?? "") { items in
            completions = items
        }
    }

    private func submitCompletion() {
        isSubmitting = true
        let text = responseText.trimmingCharacters(in: .whitespaces)
        do {
            try service.completeAssignment(assignment, response: text, userId: userId)
            withAnimation {
                showSuccess = true
                responseText = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                showSuccess = false
                isSubmitting = false
            }
        } catch {
            isSubmitting = false
            print("❌ completeAssignment error: \(error)")
        }
    }

    private func markFinished() {
        do {
            try service.finishAssignment(assignment, userId: userId)
            dismiss()
        } catch {
            print("❌ finishAssignment error: \(error)")
        }
    }
}
