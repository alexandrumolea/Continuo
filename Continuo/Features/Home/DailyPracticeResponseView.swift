import SwiftUI

struct DailyPracticeResponseView: View {
    let event: JourneyEvent
    let userId: String

    @State private var editedResponses: [String]
    @State private var isSaving = false
    @State private var showSuccess = false
    @FocusState private var focusedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    private var practice: DailyPractice? {
        DailyPractice.catalog.first { $0.id == event.practiceId }
    }
    private var prompts: [String] { practice?.prompts ?? [] }
    private var displayedPrompts: [String] {
        if includesAnchorField {
            return ["Chosen anchor (value/strength)"] + prompts
        }
        return prompts
    }
    private var accentColor: Color { practice?.categoryColor ?? ContinuoTheme.sunYellow }
    private var includesAnchorField: Bool {
        event.practiceId == "activate_sage" && (event.responses?.count ?? 0) > prompts.count
    }

    private var canSave: Bool {
        editedResponses.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    init(event: JourneyEvent, userId: String) {
        self.event = event
        self.userId = userId
        // Pre-fill with existing responses; pad to match prompt count
        let existing = event.responses ?? []
        let promptCount = DailyPractice.catalog.first { $0.id == event.practiceId }?.prompts.count ?? 0
        let includesAnchor = event.practiceId == "activate_sage" && existing.count > promptCount
        let expectedCount = includesAnchor ? (promptCount + 1) : promptCount
        let count = max(existing.count, max(expectedCount, 1))
        var filled = existing
        while filled.count < count { filled.append("") }
        _editedResponses = State(initialValue: filled)
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(practice?.emoji ?? "✨")
                            .font(.system(size: 40))
                        Text(practice?.title ?? event.title)
                            .font(ContinuoTheme.rounded(24, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(event.createdAt, style: .date)
                                .font(ContinuoTheme.rounded(12))
                            Text("·")
                            Text("+\(event.gpEarned) GP")
                                .font(ContinuoTheme.rounded(12, weight: .semibold))
                                .foregroundColor(ContinuoTheme.sunYellow)
                        }
                        .foregroundColor(ContinuoTheme.textMedium)
                    }
                    .padding(.top, 8)

                    // Prompt + editable response pairs
                    ForEach(editedResponses.indices, id: \.self) { idx in
                        VStack(alignment: .leading, spacing: 10) {
                            if idx < displayedPrompts.count {
                                HStack(alignment: .top, spacing: 6) {
                                    Text(displayedPrompts[idx])
                                        .font(ContinuoTheme.rounded(14, weight: .semibold))
                                        .foregroundColor(accentColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if idx > 0 && !(includesAnchorField && idx == 1) {
                                        Text("optional")
                                            .font(ContinuoTheme.rounded(11))
                                            .foregroundColor(ContinuoTheme.textLight)
                                            .padding(.top, 2)
                                    }
                                }
                            }

                            TextEditor(text: $editedResponses[idx])
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .frame(minHeight: 100)
                                .focused($focusedIndex, equals: idx)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.88))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    focusedIndex == idx
                                                        ? accentColor.opacity(0.5)
                                                        : Color(hex: "EDE8E0"),
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                .overlay(
                                    Group {
                                        if editedResponses[idx].isEmpty {
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

                    // Save button
                    PrimaryButton(
                        title: isSaving ? "Saving…" : "Save changes",
                        isLoading: isSaving
                    ) {
                        save()
                    }
                    .disabled(!canSave || isSaving)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .presentationDragIndicator(.visible)
        .overlay(successOverlay)
    }

    // MARK: - Success overlay
    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 12) {
                    Text("✓").font(.system(size: 48))
                    Text("Saved!")
                        .font(ContinuoTheme.rounded(20, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }

    // MARK: - Save
    private func save() {
        guard canSave else { return }
        isSaving = true
        let trimmed = editedResponses.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        do {
            try DailyPracticeService.shared.update(
                event: event,
                responses: trimmed,
                userId: userId
            )
            withAnimation { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
        } catch {
            print("❌ DailyPractice update: \(error)")
            isSaving = false
        }
    }
}
