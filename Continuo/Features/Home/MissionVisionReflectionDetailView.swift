import SwiftUI
import FirebaseFirestore

struct MissionVisionReflectionDetailView: View {
    let practice: DailyPractice
    let userId: String
    var onCompleted: ((String) -> Void)? = nil

    @State private var missionVision: MissionVision?
    @State private var listener: ListenerRegistration?

    @State private var missionPresence: Double = 0.5
    @State private var missionReflection = ""
    @State private var visionProgress: Double = 0.5
    @State private var visionStep = ""

    @State private var isSubmitting = false
    @State private var showSuccess = false
    @FocusState private var focusedField: Int?
    @Environment(\.dismiss) private var dismiss

    private let accent = Color(hex: "4F5D9F")
    private var missionPercent: Int { Int((missionPresence * 100).rounded()) }
    private var visionPercent: Int { Int((visionProgress * 100).rounded()) }

    private var hasMission: Bool {
        !(missionVision?.mission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
    private var hasVision: Bool {
        !(missionVision?.vision.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    // At least one written reflection before submitting
    private var canSubmit: Bool {
        !missionReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !visionStep.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                    // ── Mission & vision recap from Core ──
                    if !hasMission && !hasVision {
                        emptyCoreCard
                    } else {
                        coreRecapSection
                    }

                    // ── Mission presence ──
                    sliderSection(
                        question: "How present was your mission in your actions?",
                        percent: missionPercent,
                        value: $missionPresence,
                        lowLabel: "Absent",
                        highLabel: "Fully lived"
                    )

                    textSection(
                        label: "Where did your mission show up — or go missing?",
                        text: $missionReflection,
                        fieldIndex: 0,
                        optional: false
                    )

                    // ── Vision progress ──
                    sliderSection(
                        question: "How satisfied are you with your progress toward your vision?",
                        percent: visionPercent,
                        value: $visionProgress,
                        lowLabel: "Not at all",
                        highLabel: "Very satisfied"
                    )

                    textSection(
                        label: "What's one step toward your vision you can take next?",
                        text: $visionStep,
                        fieldIndex: 1,
                        optional: true
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
            listener = MissionVisionService.shared.listener(userId: userId) { missionVision = $0 }
        }
        .onDisappear { listener?.remove() }
        .overlay(successOverlay)
    }

    // MARK: - Core recap

    private var coreRecapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasMission, let mission = missionVision?.mission {
                recapBlock(label: "Your mission", text: mission)
            }
            if hasVision, let vision = missionVision?.vision {
                recapBlock(label: "Your vision", text: vision)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(accent.opacity(0.18), lineWidth: 1))
        )
    }

    private func recapBlock(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(ContinuoTheme.rounded(10, weight: .semibold))
                .foregroundColor(accent.opacity(0.75))
                .kerning(0.5)
            Text(text)
                .font(ContinuoTheme.rounded(14, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyCoreCard: some View {
        VStack(spacing: 10) {
            Text("🔭")
                .font(.system(size: 32))
            Text("No mission or vision set yet")
                .font(ContinuoTheme.rounded(14, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
            Text("Define your mission & vision in the Core section to get the most from this reflection.")
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

    // MARK: - Slider section

    private func sliderSection(
        question: String,
        percent: Int,
        value: Binding<Double>,
        lowLabel: String,
        highLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question)
                .font(ContinuoTheme.rounded(15, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Text("\(percent)%")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: percent)
                Spacer()
            }

            Slider(value: value, in: 0...1, step: 0.05)
                .tint(accent)
                .onChange(of: value.wrappedValue) { _, _ in HapticFeedback.selection() }

            HStack {
                Text(lowLabel)
                    .font(ContinuoTheme.rounded(11))
                    .foregroundColor(ContinuoTheme.textLight)
                Spacer()
                Text(highLabel)
                    .font(ContinuoTheme.rounded(11))
                    .foregroundColor(ContinuoTheme.textLight)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(accent.opacity(0.18), lineWidth: 1))
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
        let responses = [
            "\(missionPercent)%",
            missionReflection.trimmingCharacters(in: .whitespacesAndNewlines),
            "\(visionPercent)%",
            visionStep.trimmingCharacters(in: .whitespacesAndNewlines)
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
            print("❌ MissionVisionReflection complete: \(error)")
            isSubmitting = false
        }
    }
}
