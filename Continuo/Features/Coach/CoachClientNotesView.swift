import SwiftUI
import FirebaseFirestore

/// Coach's private timestamped notes about a specific client.
/// Content is never shown to the client.
struct CoachClientNotesView: View {
    let coachId: String
    let clientName: String
    let clientId: String

    @Environment(\.dismiss) private var dismiss

    @State private var entries: [CoachNoteEntry] = []
    @State private var listener: ListenerRegistration?
    @State private var isLoading = true
    @State private var draft = ""
    @State private var isSending = false
    @State private var editingEntry: CoachNoteEntry? = nil

    @FocusState private var composeFocused: Bool

    private let purple = Color(hex: "7B5EA7")
    private let accent = Color(hex: "6E443C")

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                VStack(spacing: 0) {
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView(showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 24) {
                                    headerSection
                                    privateNotice

                                    if entries.isEmpty {
                                        emptyState
                                    } else {
                                        timelineSection
                                    }

                                    Color.clear.frame(height: 1).id("scrollBottom")
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                            }
                            .scrollDismissesKeyboard(.interactively)
                            .onChange(of: entries.count) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo("scrollBottom", anchor: .bottom)
                                }
                            }
                        }
                    }

                    Divider().opacity(0.25)
                    composeBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(accent)
                }
            }
        }
        .onAppear { startListener() }
        .onDisappear { listener?.remove() }
        .sheet(item: $editingEntry) { entry in
            NoteEditSheet(
                entry: entry,
                coachId: coachId,
                clientId: clientId,
                accentColor: purple
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📝").font(.system(size: 44))
            Text("Client Notes")
                .font(ContinuoTheme.rounded(24, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)
            HStack(spacing: 4) {
                Text("About")
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(accent.opacity(0.6))
                Text(clientName)
                    .font(ContinuoTheme.rounded(13, weight: .semibold))
                    .foregroundColor(accent)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Private notice

    private var privateNotice: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundColor(purple)
            Text("These notes are private and will never be shared with \(clientName).")
                .font(ContinuoTheme.rounded(12))
                .foregroundColor(purple.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(purple.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(purple.opacity(0.18), lineWidth: 1))
        )
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                noteRow(entry, isLast: idx == entries.count - 1)
            }
        }
    }

    private func noteRow(_ entry: CoachNoteEntry, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {

            // Timeline track
            VStack(spacing: 0) {
                Circle()
                    .fill(purple)
                    .frame(width: 9, height: 9)
                    .padding(.top, 5)
                if !isLast {
                    Rectangle()
                        .fill(purple.opacity(0.18))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 9)

            // Entry content
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(entry.createdAt, style: .date)
                        .font(ContinuoTheme.rounded(11, weight: .medium))
                        .foregroundColor(ContinuoTheme.textLight)
                    Spacer()
                    Menu {
                        Button {
                            HapticFeedback.selection()
                            editingEntry = entry
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            HapticFeedback.medium()
                            deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(ContinuoTheme.textLight)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                }

                Text(entry.text)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(purple.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(purple.opacity(0.12), lineWidth: 1))
                    )
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "note.text")
                .foregroundColor(purple.opacity(0.5))
            Text("No notes yet. Add your first observation below.")
                .font(ContinuoTheme.rounded(13))
                .foregroundColor(ContinuoTheme.textMedium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(purple.opacity(0.05)))
    }

    // MARK: - Compose bar

    private var composeBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Add an observation…", text: $draft, axis: .vertical)
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.charcoal)
                .focused($composeFocused)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(purple.opacity(0.25), lineWidth: 1.5))
                )

            Button { addNote() } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(11)
                    .background(Circle().fill(
                        draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? ContinuoTheme.textLight : purple))
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ContinuoTheme.background.ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Actions

    private func startListener() {
        listener = CoachClientNoteService.shared.entriesListener(
            coachId: coachId, clientId: clientId
        ) { loaded in
            withAnimation(.easeInOut(duration: 0.2)) { entries = loaded }
            isLoading = false
        }
    }

    private func addNote() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        HapticFeedback.success()
        draft = ""
        Task {
            try? await CoachClientNoteService.shared.addEntry(
                coachId: coachId, clientId: clientId, text: text)
            await MainActor.run { isSending = false }
        }
    }

    private func deleteEntry(_ entry: CoachNoteEntry) {
        Task {
            try? await CoachClientNoteService.shared.deleteEntry(
                coachId: coachId, clientId: clientId, entry: entry)
        }
    }
}

// MARK: - Note edit sheet

private struct NoteEditSheet: View {
    let entry: CoachNoteEntry
    let coachId: String
    let clientId: String
    let accentColor: Color

    @State private var text: String
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    init(entry: CoachNoteEntry, coachId: String, clientId: String, accentColor: Color) {
        self.entry       = entry
        self.coachId     = coachId
        self.clientId    = clientId
        self.accentColor = accentColor
        _text = State(initialValue: entry.text)
    }

    private var hasChanges: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines) != entry.text
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text(entry.createdAt, style: .date)
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textMedium)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    TextEditor(text: $text)
                        .font(ContinuoTheme.rounded(15))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.9))
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(accentColor.opacity(0.2), lineWidth: 1))
                        )
                        .padding(.horizontal, 20)

                    PrimaryButton(title: isSaving ? "Saving…" : "Save changes", isLoading: isSaving) {
                        save()
                    }
                    .disabled(!hasChanges || isSaving)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task {
            try? await CoachClientNoteService.shared.updateEntry(
                coachId: coachId, clientId: clientId, entry: entry, newText: trimmed)
            await MainActor.run {
                HapticFeedback.success()
                dismiss()
            }
        }
    }
}
