import SwiftUI

/// Coach logs (or edits) a coaching session on behalf of a specific client.
struct CoachLogSessionView: View {
    let clientId: String
    let clientName: String
    let coachId: String
    var existingSession: CoachingSession? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var sessionDate: Date
    @State private var summary: String
    @State private var conclusions: String
    @State private var actions: String
    @State private var isSaving = false
    @State private var saved = false

    @FocusState private var summaryFocused: Bool

    private let accent = Color(hex: "6E443C")
    private var isEditing: Bool { existingSession != nil }

    init(clientId: String, clientName: String, coachId: String,
         existingSession: CoachingSession? = nil) {
        self.clientId        = clientId
        self.clientName      = clientName
        self.coachId         = coachId
        self.existingSession = existingSession
        _sessionDate = State(initialValue: existingSession?.sessionDate ?? Date())
        _summary     = State(initialValue: existingSession?.summaryText ?? "")
        _conclusions = State(initialValue: existingSession?.conclusions ?? "")
        _actions     = State(initialValue: existingSession?.actions     ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Header ──
                        VStack(alignment: .leading, spacing: 6) {
                            Text("🤝").font(.system(size: 44))
                            Text(isEditing ? "Edit Session" : "Log Session")
                                .font(ContinuoTheme.rounded(24, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            HStack(spacing: 4) {
                                Text("For").font(ContinuoTheme.rounded(13)).foregroundColor(accent.opacity(0.6))
                                Text(clientName).font(ContinuoTheme.rounded(13, weight: .semibold)).foregroundColor(accent)
                            }
                        }
                        .padding(.top, 4)

                        // ── Date ──
                        HStack {
                            Label("Session date", systemImage: "calendar")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Spacer()
                            DatePicker("", selection: $sessionDate, in: ...Date(),
                                       displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(accent)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.88))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
                        )

                        sessionField(title: "Session Summary", icon: "doc.text",
                                     placeholder: "What was this session about?",
                                     text: $summary)

                        sessionField(title: "Conclusions", icon: "lightbulb",
                                     placeholder: "What did the client conclude or realise?",
                                     text: $conclusions)

                        sessionField(title: "Actions", icon: "checkmark.square",
                                     placeholder: "What action did the client commit to?",
                                     text: $actions)

                        // ── Save / Done ──
                        if saved {
                            doneBanner
                        } else {
                            Button(action: save) {
                                HStack {
                                    Spacer()
                                    if !isEditing {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    Text(isEditing ? "Save Changes" : "Log Session  +30 GP")
                                        .font(ContinuoTheme.rounded(16, weight: .bold))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(accent))
                            }
                            .disabled(isSaving)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(accent)
                }
            }
        }
        .onAppear { summaryFocused = true }
    }

    // MARK: - Field

    private func sessionField(title: String, icon: String,
                              placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(ContinuoTheme.rounded(15, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.textLight)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: text)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .frame(minHeight: 88)
                    .padding(10)
                    .scrollContentBackground(.hidden)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.88))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "EDE8E0"), lineWidth: 1.5))
            )

            Text("Optional")
                .font(ContinuoTheme.rounded(11))
                .foregroundColor(ContinuoTheme.textLight)
        }
    }

    private var doneBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(accent).font(.title3)
            Text(isEditing ? "Changes saved." : "Session logged! +30 GP added for \(clientName).")
                .font(ContinuoTheme.rounded(15, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(accent.opacity(0.22), lineWidth: 1))
        )
    }

    // MARK: - Save

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        let trimSummary     = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimConclusions = conclusions.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimActions     = actions.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = existingSession {
            Task {
                try? await CoachingSessionService.shared.updateSession(
                    existing, date: sessionDate,
                    summary: trimSummary, conclusions: trimConclusions, actions: trimActions
                )
                await MainActor.run { finish() }
            }
        } else {
            try? CoachingSessionService.shared.logSessionByCoach(
                clientId: clientId, coachId: coachId,
                sessionDate: sessionDate,
                summary: trimSummary, conclusions: trimConclusions, actions: trimActions
            )
            finish()
        }
    }

    private func finish() {
        HapticFeedback.success()
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { dismiss() }
    }
}
