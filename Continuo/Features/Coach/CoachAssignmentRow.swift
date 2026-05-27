import SwiftUI
import FirebaseFirestore

// MARK: - Assignment row (swipeable + expandable) — used in CoachClientActivityView

struct CoachAssignmentRow: View {
    let assignment: Assignment
    let completions: [AssignmentCompletion]
    let clientName: String
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onDelete: () -> Void

    @State private var swipeOffset: CGFloat = 0
    private let deleteWidth: CGFloat = 72

    @State private var expandedCompletionId: String? = nil
    @State private var draft = ""
    @State private var editingMsg: ThreadMessage? = nil
    @State private var editMsgDraft = ""
    @FocusState private var inputFocused: Bool
    @FocusState private var editMsgFocused: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete reveal
            Button {
                HapticFeedback.medium()
                withAnimation(.spring(response: 0.25)) { swipeOffset = 0 }
                onDelete()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill").font(.system(size: 16))
                    Text("Delete").font(ContinuoTheme.rounded(10, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: deleteWidth).frame(maxHeight: .infinity)
            }
            .background(Color.red.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .opacity(swipeOffset < -8 ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: swipeOffset)

            cardContent.offset(x: swipeOffset)
        }
        .clipped()
        .gesture(
            DragGesture(minimumDistance: 15, coordinateSpace: .local)
                .onChanged { val in
                    guard val.translation.width < 0 else { return }
                    swipeOffset = max(val.translation.width, -deleteWidth)
                }
                .onEnded { val in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        swipeOffset = val.translation.width < -(deleteWidth / 2) ? -deleteWidth : 0
                    }
                }
        )
    }

    // MARK: - Card

    private var cardContent: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header (tap to expand)
                Button {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.25)) { swipeOffset = 0 }
                    onToggleExpand()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ContinuoTheme.terracotta.opacity(0.10))
                                .frame(width: 42, height: 42)
                            Text(assignment.emoji ?? "🎯").font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(assignment.title)
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 6) {
                                statusPill
                                if !completions.isEmpty {
                                    Text("·").foregroundColor(ContinuoTheme.textLight)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10)).foregroundColor(ContinuoTheme.olive)
                                    Text("\(completions.count)× completed")
                                        .font(ContinuoTheme.rounded(11))
                                        .foregroundColor(ContinuoTheme.textMedium)
                                }
                            }

                            if !assignment.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(assignment.description)
                                    .font(ContinuoTheme.rounded(13))
                                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }

                            HStack(spacing: 10) {
                                Label("\(assignment.gpReward) GP", systemImage: "star.fill")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.sunOrange)
                                if let expiry = assignment.expiresAt {
                                    Label(expiry.formatted(date: .abbreviated, time: .omitted),
                                          systemImage: "calendar")
                                        .font(ContinuoTheme.rounded(11))
                                        .foregroundColor(ContinuoTheme.textLight)
                                }
                            }
                        }

                        Spacer(minLength: 4)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption).foregroundColor(ContinuoTheme.textLight).padding(.top, 2)
                    }
                }
                .buttonStyle(.plain)

                // Expanded: completions
                if isExpanded {
                    Divider().opacity(0.3).padding(.vertical, 12)
                    if completions.isEmpty {
                        HStack {
                            Image(systemName: "clock").font(.caption).foregroundColor(ContinuoTheme.textLight)
                            Text("No responses yet")
                                .font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textLight)
                        }.padding(.bottom, 4)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(completions) { completion in
                                completionCard(completion)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Status pill

    private var statusPill: some View {
        let (label, color): (String, Color) = {
            switch assignment.status {
            case .active:   return ("Active",   ContinuoTheme.olive)
            case .finished: return ("Finished", ContinuoTheme.sunOrange)
            case .paused:   return ("Paused",   ContinuoTheme.textLight)
            }
        }()
        return Text(label)
            .font(ContinuoTheme.rounded(10, weight: .semibold)).foregroundColor(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    // MARK: - Completion card

    private func completionCard(_ completion: AssignmentCompletion) -> some View {
        let isExpanded = expandedCompletionId == completion.id
        let thread = resolvedThread(completion)

        return VStack(alignment: .leading, spacing: 10) {
            Text(completion.completedAt, style: .date)
                .font(ContinuoTheme.rounded(11, weight: .medium))
                .foregroundColor(ContinuoTheme.textLight)

            if !completion.response.isEmpty {
                Text(completion.response)
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "F5F2EC").opacity(0.8)))
            }

            if !thread.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(thread) { msg in messageBubble(msg, completion: completion) }
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom, spacing: 8) {
                        TextField("Write a reply…", text: $draft, axis: .vertical)
                            .font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.charcoal)
                            .focused($inputFocused).lineLimit(1...5).padding(10)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.9))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(ContinuoTheme.olive.opacity(0.4), lineWidth: 1.5)))
                        Button { sendMessage(to: completion) } label: {
                            Image(systemName: "paperplane.fill").font(.subheadline)
                                .foregroundColor(.white).padding(10)
                                .background(Circle().fill(
                                    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? ContinuoTheme.textLight : ContinuoTheme.olive))
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Button {
                        expandedCompletionId = nil; draft = ""; inputFocused = false
                    } label: {
                        Text("Cancel").font(ContinuoTheme.rounded(12)).foregroundColor(ContinuoTheme.textLight)
                    }
                }
            } else {
                HStack {
                    Button {
                        HapticFeedback.selection()
                        draft = ""; expandedCompletionId = completion.id; inputFocused = true
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                            .font(ContinuoTheme.rounded(12)).foregroundColor(ContinuoTheme.textMedium)
                    }
                    Spacer()
                    likeButton(completion)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(ContinuoTheme.charcoal.opacity(0.04)))
    }

    // MARK: - Message bubble

    private func messageBubble(_ msg: ThreadMessage, completion: AssignmentCompletion) -> some View {
        let isCoach = msg.role == "coach"
        let color: Color = isCoach ? ContinuoTheme.olive : ContinuoTheme.terracotta
        let label = isCoach ? "You" : clientName
        let isEditing = editingMsg?.id == msg.id

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isCoach ? "arrowshape.turn.up.left.fill" : "person.circle.fill")
                    .font(.subheadline).foregroundColor(color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(ContinuoTheme.rounded(10, weight: .semibold)).foregroundColor(color)
                    if !isEditing {
                        Text(msg.text).font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.charcoal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                if isCoach && !isEditing {
                    Menu {
                        Button {
                            editMsgDraft = msg.text; editingMsg = msg; editMsgFocused = true
                        } label: { Label("Edit", systemImage: "pencil") }
                    } label: {
                        Image(systemName: "ellipsis").font(.caption)
                            .foregroundColor(ContinuoTheme.textLight).padding(6)
                    }
                }
            }

            if isEditing {
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Edit message…", text: $editMsgDraft, axis: .vertical)
                        .font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.charcoal)
                        .focused($editMsgFocused).lineLimit(1...5).padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.9))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(color.opacity(0.4), lineWidth: 1.5)))
                    Button {
                        let text = editMsgDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        HapticFeedback.success()
                        Task {
                            try? await AssignmentService.shared.editMessage(
                                completion: completion, messageId: msg.id, newText: text)
                        }
                        editingMsg = nil; editMsgFocused = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill").font(.title3)
                            .foregroundColor(
                                editMsgDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? ContinuoTheme.textLight : color)
                    }
                    .disabled(editMsgDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Button { editingMsg = nil; editMsgFocused = false } label: {
                    Text("Cancel").font(ContinuoTheme.rounded(11)).foregroundColor(ContinuoTheme.textLight)
                }
            }
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.07)))
    }

    // MARK: - Helpers

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

    private func likeButton(_ completion: AssignmentCompletion) -> some View {
        Button {
            HapticFeedback.light()
            Task { try? await AssignmentService.shared.setLiked(completion, liked: !completion.isLiked) }
        } label: {
            Image(systemName: completion.isLiked ? "heart.fill" : "heart")
                .font(.callout)
                .foregroundColor(completion.isLiked ? .pink : ContinuoTheme.textLight)
                .contentTransition(.symbolEffect(.replace)).padding(6)
                .background(Circle().fill(completion.isLiked ? Color.pink.opacity(0.1) : Color.clear))
        }
    }

    private func sendMessage(to completion: AssignmentCompletion) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let id = completion.id else { return }
        HapticFeedback.success()
        Task { try? await AssignmentService.shared.appendMessage(completionId: id, role: "coach", text: text) }
        expandedCompletionId = nil; draft = ""; inputFocused = false
    }
}
