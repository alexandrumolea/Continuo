import SwiftUI
import FirebaseFirestore

struct PriorityAlignmentDetailView: View {
    let practice: DailyPractice
    let userId: String
    var onCompleted: ((String) -> Void)? = nil

    @State private var priorities: [PersonalPriority] = []
    @State private var listener: ListenerRegistration?
    @State private var alignment: Double = 0.5
    @State private var learnedResponse = ""
    @State private var tomorrowResponse = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @FocusState private var focusedField: Int?
    @Environment(\.dismiss) private var dismiss

    private var alignmentPercent: Int { Int((alignment * 100).rounded()) }
    private let agencyColor = Color(hex: "4E7040")

    // At least one text field must have content before submitting
    private var canSubmit: Bool {
        !learnedResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !tomorrowResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                    // ── Priorities list ──
                    if priorities.isEmpty {
                        emptyPrioritiesCard
                    } else {
                        prioritiesSection
                    }

                    // ── Alignment slider ──
                    alignmentSection

                    // ── What did I learn? ──
                    textSection(
                        label: "What did I learn from today?",
                        placeholder: "Write your response here…",
                        text: $learnedResponse,
                        fieldIndex: 0
                    )

                    // ── What will I do tomorrow? ──
                    textSection(
                        label: "What would I like to do tomorrow to be more aligned with my priorities?",
                        placeholder: "Write your response here…",
                        text: $tomorrowResponse,
                        fieldIndex: 1
                    )

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
            listener = PrioritiesService.shared.prioritiesListener(userId: userId) { priorities = $0 }
        }
        .onDisappear { listener?.remove() }
        .overlay(successOverlay)
    }

    // MARK: - Priorities list

    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your top priorities")
                .font(ContinuoTheme.rounded(14, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            let top4 = Array(priorities.prefix(4))
            VStack(spacing: 0) {
                ForEach(Array(top4.enumerated()), id: \.element.id) { idx, priority in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(agencyColor)
                                .frame(width: 26, height: 26)
                            Text("\(idx + 1)")
                                .font(ContinuoTheme.rounded(12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text(priority.text)
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    if idx < top4.count - 1 {
                        Divider()
                            .padding(.horizontal, 14)
                            .opacity(0.4)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "EDE8E0"), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var emptyPrioritiesCard: some View {
        VStack(spacing: 10) {
            Text("📌")
                .font(.system(size: 32))
            Text("No priorities set yet")
                .font(ContinuoTheme.rounded(14, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
            Text("Add your priorities in the Core section to get the most from this practice.")
                .font(ContinuoTheme.rounded(13))
                .foregroundColor(ContinuoTheme.textMedium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "EDE8E0"), lineWidth: 1)
                )
        )
    }

    // MARK: - Alignment slider section

    private var alignmentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How well did my actions align with my priorities today?")
                .font(ContinuoTheme.rounded(15, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)

            // Large percentage readout
            HStack {
                Spacer()
                Text("\(alignmentPercent)%")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(agencyColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: alignmentPercent)
                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(agencyColor.opacity(0.12))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [agencyColor.opacity(0.6), agencyColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * alignment), height: 10)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: alignment)
                }
            }
            .frame(height: 10)

            // Slider — 5 % steps so haptic fires at meaningful intervals
            Slider(value: $alignment, in: 0...1, step: 0.05)
                .tint(agencyColor)
                .onChange(of: alignment) { _, _ in
                    HapticFeedback.selection()
                }

            // Endpoint labels
            HStack {
                Text("0%")
                    .font(ContinuoTheme.rounded(11))
                    .foregroundColor(ContinuoTheme.textLight)
                Spacer()
                Text("100%")
                    .font(ContinuoTheme.rounded(11))
                    .foregroundColor(ContinuoTheme.textLight)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(agencyColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(agencyColor.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Reusable text section

    private func textSection(
        label: String,
        placeholder: String,
        text: Binding<String>,
        fieldIndex: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
                Text(label)
                    .font(ContinuoTheme.rounded(15, weight: .medium))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
                if fieldIndex > 0 {
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
                                        ? agencyColor.opacity(0.6)
                                        : Color(hex: "EDE8E0"),
                                    lineWidth: 1.5
                                )
                        )
                )
                .overlay(
                    Group {
                        if text.wrappedValue.isEmpty {
                            Text(placeholder)
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

        let responses = [
            "\(alignmentPercent)%",
            learnedResponse.trimmingCharacters(in: .whitespacesAndNewlines),
            tomorrowResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        ]

        do {
            try DailyPracticeService.shared.complete(
                practice: practice,
                responses: responses,
                userId: userId
            )
            onCompleted?(practice.id)
            HapticFeedback.success()
            withAnimation { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
        } catch {
            print("❌ PriorityAlignment complete: \(error)")
            isSubmitting = false
        }
    }
}
