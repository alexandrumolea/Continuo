import SwiftUI
import FirebaseFirestore

struct ActivateSageDetailView: View {
    let practice: DailyPractice
    let userId: String
    var onCompleted: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var values: [PersonalValue] = []
    @State private var strengths: [PersonalStrength] = []
    @State private var valuesListener: ListenerRegistration?
    @State private var strengthsListener: ListenerRegistration?

    @State private var selectedAnchor: AnchorItem? = nil
    @State private var answer1 = ""
    @State private var answer2 = ""
    @State private var answer3 = ""
    @State private var completed = false

    private let accentColor = Color(hex: "7B5EA7")

    // MARK: - Anchor item model

    struct AnchorItem: Identifiable, Equatable {
        var id: String
        var text: String
        var kind: Kind

        enum Kind { case value, strength }

        var kindLabel: String { kind == .value ? "Value" : "Strength" }
        var chipColor: Color { kind == .value ? ContinuoTheme.terracotta : ContinuoTheme.olive }
    }

    private var valueAnchors: [AnchorItem] {
        values.map { AnchorItem(id: "v_\($0.id ?? UUID().uuidString)", text: $0.text, kind: .value) }
    }

    private var strengthAnchors: [AnchorItem] {
        strengths.map { AnchorItem(id: "s_\($0.id ?? UUID().uuidString)", text: $0.text, kind: .strength) }
    }

    private var canComplete: Bool {
        selectedAnchor != nil &&
        !answer1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !answer2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !answer3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text(practice.emoji)
                            .font(.system(size: 44))
                        Text(practice.title)
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("Activate the wisest part of yourself")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(accentColor.opacity(0.7))
                    }
                    .padding(.top, 36)

                    // ── Anchor picker ──
                    anchorSection

                    // ── Reflection questions (revealed after anchor is chosen) ──
                    if selectedAnchor != nil {
                        reflectionSection
                    }

                    // ── Complete / Done banner ──
                    if completed {
                        doneBanner
                    } else {
                        completeButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            valuesListener    = ValuesService.shared.valuesListener(userId: userId)    { values    = $0 }
            strengthsListener = StrengthsService.shared.strengthsListener(userId: userId) { strengths = $0 }
        }
        .onDisappear {
            valuesListener?.remove()
            strengthsListener?.remove()
        }
    }

    // MARK: - Anchor section

    private var anchorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose your anchor")
                .font(ContinuoTheme.rounded(17, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            if values.isEmpty && strengths.isEmpty {
                emptyCoreHint
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if !valueAnchors.isEmpty {
                        anchorGroup(label: "Values",
                                    labelColor: ContinuoTheme.terracotta,
                                    items: valueAnchors)
                    }
                    if !strengthAnchors.isEmpty {
                        anchorGroup(label: "Strengths",
                                    labelColor: ContinuoTheme.olive,
                                    items: strengthAnchors)
                    }
                }
            }
        }
    }

    private func anchorGroup(label: String, labelColor: Color, items: [AnchorItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(ContinuoTheme.rounded(11, weight: .semibold))
                .foregroundColor(labelColor.opacity(0.75))
                .textCase(.uppercase)
                .kerning(0.5)

            FlowLayout(spacing: 8) {
                ForEach(items) { item in
                    anchorChip(item)
                }
            }
        }
    }

    private func anchorChip(_ item: AnchorItem) -> some View {
        let isSelected = selectedAnchor == item
        return Button { withAnimation(.easeInOut(duration: 0.15)) { selectedAnchor = item } } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(item.text)
                    .font(ContinuoTheme.rounded(13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : item.chipColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? item.chipColor : item.chipColor.opacity(0.09))
                    .overlay(
                        Capsule().stroke(item.chipColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var emptyCoreHint: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16))
                .foregroundColor(accentColor.opacity(0.7))
                .padding(.top, 1)
            Text("Add at least one value or strength in the **Core** tab to activate your sage.")
                .font(ContinuoTheme.rounded(13))
                .foregroundColor(ContinuoTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accentColor.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.18), lineWidth: 1))
        )
    }

    // MARK: - Reflection section

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let anchor = selectedAnchor {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundColor(anchor.chipColor)
                    Text("Reflecting on \"\(anchor.text)\"")
                        .font(ContinuoTheme.rounded(14, weight: .medium))
                        .foregroundColor(anchor.chipColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(anchor.chipColor.opacity(0.09)))
            }

            reflectionField(question: practice.prompts[0], text: $answer1, index: 0)
            reflectionField(question: practice.prompts[1], text: $answer2, index: 1)
            reflectionField(question: practice.prompts[2], text: $answer3, index: 2)
        }
    }

    private func reflectionField(question: String, text: Binding<String>, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 26, height: 26)
                    Text("\(index + 1)")
                        .font(ContinuoTheme.rounded(12, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(question)
                    .font(ContinuoTheme.rounded(14, weight: .medium))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextEditor(text: text)
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.charcoal)
                .frame(minHeight: 90)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.88))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "EDE8E0"), lineWidth: 1.5))
                )
                .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Complete button

    private var completeButton: some View {
        Button(action: complete) {
            HStack {
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("Complete  +\(practice.gpReward) GP")
                    .font(ContinuoTheme.rounded(16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(canComplete ? accentColor : ContinuoTheme.textLight)
            )
        }
        .disabled(!canComplete)
        .animation(.easeInOut(duration: 0.2), value: canComplete)
    }

    private var doneBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(accentColor)
                .font(.title3)
            Text("Sage activated! Well done.")
                .font(ContinuoTheme.rounded(15, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accentColor.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.22), lineWidth: 1))
        )
    }

    // MARK: - Complete action

    private func complete() {
        guard canComplete, let anchor = selectedAnchor else { return }
        let anchorLabel = "\(anchor.text) (\(anchor.kindLabel))"
        let responses = [anchorLabel, answer1, answer2, answer3]
        try? DailyPracticeService.shared.complete(practice: practice, responses: responses, userId: userId)
        withAnimation { completed = true }
        onCompleted?(practice.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}
