import SwiftUI
import FirebaseFirestore

struct YearlyGoalsCheckInDetailView: View {
    let practice: DailyPractice
    let userId: String
    var onCompleted: ((String) -> Void)? = nil

    @State private var goals: [Goal] = []
    @State private var listener: ListenerRegistration?

    @State private var responses: [String]
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @FocusState private var focusedField: Int?
    @Environment(\.dismiss) private var dismiss

    private let accent = Color(hex: "C87B3E")

    init(practice: DailyPractice, userId: String, onCompleted: ((String) -> Void)? = nil) {
        self.practice = practice
        self.userId = userId
        self.onCompleted = onCompleted
        _responses = State(initialValue: Array(repeating: "", count: practice.prompts.count))
    }

    private var overallPercent: Int {
        guard !goals.isEmpty else { return 0 }
        let avg = goals.reduce(0.0) { $0 + $1.progress } / Double(goals.count)
        return Int((avg * 100).rounded())
    }

    private var canSubmit: Bool {
        responses.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text(practice.emoji)
                            .font(.system(size: 44))
                        Text(practice.title)
                            .font(ContinuoTheme.rounded(26, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        HStack(spacing: 6) {
                            Text(practice.category)
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textMedium)
                            Text("·")
                                .foregroundColor(ContinuoTheme.textLight)
                            Text("+\(practice.gpReward) GP")
                                .font(ContinuoTheme.rounded(12, weight: .semibold))
                                .foregroundColor(ContinuoTheme.sunYellow)
                        }
                    }
                    .padding(.top, 36)

                    // ── Goals recap ──
                    if goals.isEmpty {
                        emptyGoalsCard
                    } else {
                        overallProgressCard
                        goalsSection
                    }

                    // ── Reflection questions ──
                    ForEach(Array(practice.prompts.enumerated()), id: \.offset) { idx, prompt in
                        textSection(
                            label: prompt,
                            text: $responses[idx],
                            fieldIndex: idx,
                            optional: idx > 0
                        )
                    }

                    // ── Submit ──
                    PrimaryButton(
                        title: isSubmitting ? "Saving…" : "Complete · +\(practice.gpReward) GP",
                        isLoading: isSubmitting
                    ) {
                        submit()
                    }
                    .disabled(!canSubmit || isSubmitting)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            listener = GoalService.shared.goalsListener(userId: userId) { goals = $0 }
        }
        .onDisappear { listener?.remove() }
        .overlay(successOverlay)
    }

    // MARK: - Overall progress

    private var overallProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall progress")
                .font(ContinuoTheme.rounded(13, weight: .semibold))
                .foregroundColor(ContinuoTheme.textMedium)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(overallPercent)%")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Text("across \(goals.count) goal\(goals.count == 1 ? "" : "s")")
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(ContinuoTheme.textMedium)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accent.opacity(0.12))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accent)
                        .frame(width: geo.size.width * (Double(overallPercent) / 100.0), height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(accent.opacity(0.18), lineWidth: 1))
        )
    }

    // MARK: - Goals list

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your goals")
                .font(ContinuoTheme.rounded(14, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            VStack(spacing: 0) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { idx, goal in
                    HStack(spacing: 12) {
                        Text(goal.emoji ?? goal.type.emoji)
                            .font(.system(size: 22))
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(goal.title)
                                .font(ContinuoTheme.rounded(14, weight: .medium))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 8) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(goal.type.color.opacity(0.12))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(goal.type.color)
                                            .frame(width: geo.size.width * goal.progress, height: 6)
                                    }
                                }
                                .frame(height: 6)

                                Text("\(Int((goal.progress * 100).rounded()))%")
                                    .font(ContinuoTheme.rounded(11, weight: .semibold))
                                    .foregroundColor(goal.type.color)
                                    .frame(minWidth: 32, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    if idx < goals.count - 1 {
                        Divider()
                            .padding(.horizontal, 14)
                            .opacity(0.4)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.7))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var emptyGoalsCard: some View {
        VStack(spacing: 10) {
            Text("🎯")
                .font(.system(size: 32))
            Text("No goals yet")
                .font(ContinuoTheme.rounded(14, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
            Text("Add a goal in your focus list to make this check-in more meaningful — you can still reflect below.")
                .font(ContinuoTheme.rounded(13))
                .foregroundColor(ContinuoTheme.textMedium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
        )
    }

    // MARK: - Text section

    private func textSection(
        label: String,
        text: Binding<String>,
        fieldIndex: Int,
        optional: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
                Text(label)
                    .font(ContinuoTheme.rounded(15, weight: .medium))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
                if optional {
                    Text("optional")
                        .font(ContinuoTheme.rounded(11))
                        .foregroundColor(ContinuoTheme.textLight)
                        .padding(.top, 3)
                }
            }

            TextEditor(text: text)
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.charcoal)
                .frame(minHeight: 110)
                .focused($focusedField, equals: fieldIndex)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    focusedField == fieldIndex
                                        ? accent.opacity(0.6)
                                        : Color(hex: "EDE8E0"),
                                    lineWidth: 1.5
                                )
                        )
                )
                .overlay(
                    Group {
                        if text.wrappedValue.isEmpty {
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

    // MARK: - Success overlay

    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 14) {
                    Text("✓")
                        .font(.system(size: 52))
                    Text("Done!")
                        .font(ContinuoTheme.rounded(22, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Text("+\(practice.gpReward) GP earned")
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

    // MARK: - Submit

    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true

        // Order matches the catalog prompts for this practice
        let trimmed = responses.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        do {
            try DailyPracticeService.shared.complete(
                practice: practice,
                responses: trimmed,
                userId: userId
            )
            onCompleted?(practice.id)
            HapticFeedback.success()
            withAnimation { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
        } catch {
            print("❌ YearlyGoalsCheckIn complete: \(error)")
            isSubmitting = false
        }
    }
}
