import SwiftUI
import FirebaseFirestore

struct CoachClientActivityView: View {
    let client: ContinuoUser
    let coachId: String

    @State private var assignments: [Assignment] = []
    @State private var completions: [AssignmentCompletion] = []
    @State private var assignmentsListener: ListenerRegistration?
    @State private var completionsListener: ListenerRegistration?
    @State private var expandedAssignmentId: String? = nil

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            if assignments.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(assignments) { assignment in
                            CoachAssignmentRow(
                                assignment: assignment,
                                completions: completionsFor(assignment),
                                clientName: client.displayName,
                                isExpanded: expandedAssignmentId == assignment.id,
                                onToggleExpand: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedAssignmentId = expandedAssignmentId == assignment.id
                                            ? nil
                                            : assignment.id
                                    }
                                },
                                onDelete: {
                                    Task { try? await AssignmentService.shared.deleteAssignment(assignment) }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(client.displayName)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            guard let clientId = client.id else { return }
            // Single-field query — no composite index required; filter by coachId client-side
            assignmentsListener = AssignmentService.shared.assignmentsForClientListener(clientId: clientId) { all in
                assignments = all.filter { $0.coachId == coachId }
            }
            completionsListener = AssignmentService.shared.coachClientCompletionsListener(
                clientId: clientId,
                coachId: coachId,
                onChange: { completions = $0 }
            )
        }
        .onDisappear {
            assignmentsListener?.remove()
            completionsListener?.remove()
        }
    }

    private func completionsFor(_ assignment: Assignment) -> [AssignmentCompletion] {
        completions
            .filter { $0.assignmentId == assignment.id }
            .sorted { $0.completedAt > $1.completedAt }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("📭").font(.system(size: 44))
            Text("No assignments sent to\n\(client.displayName) yet.")
                .font(ContinuoTheme.rounded(15))
                .foregroundColor(ContinuoTheme.textMedium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Assignment row (swipeable + expandable)

struct CoachAssignmentRow: View {
    let assignment: Assignment
    let completions: [AssignmentCompletion]
    let clientName: String
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onDelete: () -> Void

    @State private var swipeOffset: CGFloat = 0
    private let deleteWidth: CGFloat = 72

    // Per-row reply / edit state
    @State private var expandedCompletionId: String? = nil
    @State private var draft = ""
    @State private var editingMsg: ThreadMessage? = nil
    @State private var editMsgDraft = ""
    @FocusState private var inputFocused: Bool
    @FocusState private var editMsgFocused: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            // ── Delete button ──
            Button {
                withAnimation(.spring(response: 0.25)) { swipeOffset = 0 }
                onDelete()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill").font(.system(size: 16))
                    Text("Delete").font(ContinuoTheme.rounded(10, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: deleteWidth)
                .frame(maxHeight: .infinity)
            }
            .background(Color.red.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .opacity(swipeOffset < -8 ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: swipeOffset)

            // ── Card ──
            cardContent
                .offset(x: swipeOffset)
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

    // MARK: - Card content

    private var cardContent: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header (tap to expand) ──
                Button {
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
                            // Title + status
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
                                        .font(.system(size: 10))
                                        .foregroundColor(ContinuoTheme.olive)
                                    Text("\(completions.count)× completed")
                                        .font(ContinuoTheme.rounded(11))
                                        .foregroundColor(ContinuoTheme.textMedium)
                                }
                            }

                            // Description
                            if !assignment.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(assignment.description)
                                    .font(ContinuoTheme.rounded(13))
                                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }

                            // Meta row: GP · expiry
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
                            .font(.caption)
                            .foregroundColor(ContinuoTheme.textLight)
                            .padding(.top, 2)
                    }
                }
                .buttonStyle(.plain)

                // ── Expanded: completions ──
                if isExpanded {
                    Divider().opacity(0.3).padding(.vertical, 12)

                    if completions.isEmpty {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(ContinuoTheme.textLight)
                            Text("No responses yet")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textLight)
                        }
                        .padding(.bottom, 4)
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
            .font(ContinuoTheme.rounded(10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    // MARK: - Completion card

    private func completionCard(_ completion: AssignmentCompletion) -> some View {
        let isCompletionExpanded = expandedCompletionId == completion.id
        let thread = resolvedThread(completion)

        return VStack(alignment: .leading, spacing: 10) {
            // Date
            Text(completion.completedAt, style: .date)
                .font(ContinuoTheme.rounded(11, weight: .medium))
                .foregroundColor(ContinuoTheme.textLight)

            // Client response
            if !completion.response.isEmpty {
                Text(completion.response)
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "F5F2EC").opacity(0.8)))
            }

            // Thread
            if !thread.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(thread) { msg in
                        messageBubble(msg, completion: completion)
                    }
                }
            }

            // Reply input
            if isCompletionExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom, spacing: 8) {
                        TextField("Write a reply…", text: $draft, axis: .vertical)
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .focused($inputFocused)
                            .lineLimit(1...5)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.9))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(ContinuoTheme.olive.opacity(0.4), lineWidth: 1.5)))

                        Button { sendMessage(to: completion) } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(
                                    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? ContinuoTheme.textLight
                                        : ContinuoTheme.olive
                                ))
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Button {
                        expandedCompletionId = nil
                        draft = ""
                        inputFocused = false
                    } label: {
                        Text("Cancel")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textLight)
                    }
                }
            } else {
                HStack {
                    Button {
                        draft = ""
                        expandedCompletionId = completion.id
                        inputFocused = true
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
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

                if isCoach && !isEditing {
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
                        Task {
                            try? await AssignmentService.shared.editMessage(
                                completion: completion, messageId: msg.id, newText: text
                            )
                        }
                        editingMsg = nil
                        editMsgFocused = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(
                                editMsgDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? ContinuoTheme.textLight : color
                            )
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
            Task { try? await AssignmentService.shared.setLiked(completion, liked: !completion.isLiked) }
        } label: {
            Image(systemName: completion.isLiked ? "heart.fill" : "heart")
                .font(.callout)
                .foregroundColor(completion.isLiked ? .pink : ContinuoTheme.textLight)
                .contentTransition(.symbolEffect(.replace))
                .padding(6)
                .background(Circle().fill(completion.isLiked ? Color.pink.opacity(0.1) : Color.clear))
        }
    }

    private func sendMessage(to completion: AssignmentCompletion) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let id = completion.id else { return }
        Task { try? await AssignmentService.shared.appendMessage(completionId: id, role: "coach", text: text) }
        expandedCompletionId = nil
        draft = ""
        inputFocused = false
    }
}
