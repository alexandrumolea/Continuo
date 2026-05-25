import SwiftUI

struct LogCoachingSessionView: View {
    let userId: String
    let existingSession: CoachingSession?   // nil → new, non-nil → edit

    @Environment(\.dismiss) private var dismiss

    @State private var sessionDate: Date
    @State private var conclusions: String
    @State private var actions: String
    @State private var saved = false

    private let accent = Color(hex: "6E443C")
    private var isEditing: Bool { existingSession != nil }

    init(userId: String, existingSession: CoachingSession? = nil) {
        self.userId = userId
        self.existingSession = existingSession
        _sessionDate = State(initialValue: existingSession?.sessionDate ?? Date())
        _conclusions = State(initialValue: existingSession?.conclusions ?? "")
        _actions     = State(initialValue: existingSession?.actions     ?? "")
        _saved       = State(initialValue: false)
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
                            Text("🤝")
                                .font(.system(size: 44))
                            Text(isEditing ? "Edit Session" : "Log Coaching Session")
                                .font(ContinuoTheme.rounded(24, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("Only the session itself is required")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(accent.opacity(0.65))
                        }
                        .padding(.top, 4)

                        // ── Date ──
                        HStack {
                            Label("Session date", systemImage: "calendar")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Spacer()
                            DatePicker(
                                "",
                                selection: $sessionDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
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

                        // ── Conclusions ──
                        optionalField(
                            title: "Conclusions",
                            icon: "lightbulb",
                            placeholder: "What did you learn or realise during the session?",
                            text: $conclusions
                        )

                        // ── Actions ──
                        optionalField(
                            title: "Actions",
                            icon: "checkmark.square",
                            placeholder: "What will you commit to do differently?",
                            text: $actions
                        )

                        // ── Primary button / Done banner ──
                        if saved {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(accent)
                                    .font(.title3)
                                Text(isEditing ? "Changes saved." : "Session logged! +30 GP added.")
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
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(accent)
                }
            }
        }
    }

    // MARK: - Optional field

    private func optionalField(title: String, icon: String, placeholder: String, text: Binding<String>) -> some View {
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
                    .frame(minHeight: 96)
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

    // MARK: - Save

    private func save() {
        let trimmedConclusions = conclusions.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedActions     = actions.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = existingSession {
            Task {
                try? await CoachingSessionService.shared.updateSession(
                    existing,
                    date:        sessionDate,
                    conclusions: trimmedConclusions,
                    actions:     trimmedActions
                )
            }
        } else {
            try? CoachingSessionService.shared.logSession(
                userId:      userId,
                sessionDate: sessionDate,
                conclusions: trimmedConclusions,
                actions:     trimmedActions
            )
        }
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { dismiss() }
    }
}
