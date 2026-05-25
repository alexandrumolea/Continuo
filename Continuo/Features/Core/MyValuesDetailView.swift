import SwiftUI
import FirebaseFirestore

struct MyValuesDetailView: View {
    let userId: String

    @State private var values: [PersonalValue] = []
    @State private var listener: ListenerRegistration?
    @State private var newValueText = ""
    @FocusState private var inputFocused: Bool

    private let maxValues = 10
    private let guidingQuestions = [
        "What is more important to you than money?",
        "Think of a person you admire. What is it about that person that you admire?",
        "What characteristics would make older, wiser you proud?"
    ]

    private var canAdd: Bool {
        values.count < maxValues &&
        !newValueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🧭")
                            .font(.system(size: 44))
                        Text("My Values")
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("Up to \(maxValues) personal values — 5 shown on card")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                    .padding(.top, 4)

                    // ── Current values ──
                    if !values.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your values")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)

                            FlowLayout(spacing: 10) {
                                ForEach(values) { value in
                                    valueChip(value)
                                }
                            }
                        }
                    }

                    // ── Add value ──
                    if values.count < maxValues {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(values.isEmpty ? "Add your first value" : "Add another value")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)

                            HStack(spacing: 10) {
                                TextField("e.g. Family, Honesty, Growth…", text: $newValueText)
                                    .font(ContinuoTheme.rounded(14))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .focused($inputFocused)
                                    .submitLabel(.done)
                                    .onSubmit { addValue() }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.88))
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    inputFocused
                                                        ? ContinuoTheme.terracotta.opacity(0.5)
                                                        : Color(hex: "EDE8E0"),
                                                    lineWidth: 1.5
                                                ))
                                    )

                                Button(action: addValue) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(canAdd ? ContinuoTheme.terracotta : ContinuoTheme.textLight)
                                }
                                .disabled(!canAdd)
                            }

                            Text("\(maxValues - values.count) remaining")
                                .font(ContinuoTheme.rounded(11))
                                .foregroundColor(ContinuoTheme.textLight)
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(ContinuoTheme.olive)
                                .font(.title3)
                            Text("You've defined all 10 values.\nDelete one to add another.")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14)
                            .fill(ContinuoTheme.olive.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(ContinuoTheme.olive.opacity(0.22), lineWidth: 1)))
                    }

                    // ── Guiding questions ──
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Guiding questions")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)

                        ForEach(Array(guidingQuestions.enumerated()), id: \.offset) { idx, q in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(ContinuoTheme.terracotta)
                                        .frame(width: 28, height: 28)
                                    Text("\(idx + 1)")
                                        .font(ContinuoTheme.rounded(12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Text(q)
                                    .font(ContinuoTheme.rounded(14))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(ContinuoTheme.terracotta.opacity(0.06))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(ContinuoTheme.terracotta.opacity(0.18), lineWidth: 1))
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            listener = ValuesService.shared.valuesListener(userId: userId) { values = $0 }
        }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Value chip
    private func valueChip(_ value: PersonalValue) -> some View {
        HStack(spacing: 6) {
            Text(value.text)
                .font(ContinuoTheme.rounded(14, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)

            Button {
                Task { try? await ValuesService.shared.deleteValue(value) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(ContinuoTheme.textLight)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(ContinuoTheme.terracotta.opacity(0.09))
                .overlay(Capsule().stroke(ContinuoTheme.terracotta.opacity(0.22), lineWidth: 1))
        )
    }

    // MARK: - Add
    private func addValue() {
        let text = newValueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, values.count < maxValues else { return }
        let v = PersonalValue(userId: userId, text: text, createdAt: Date())
        try? ValuesService.shared.addValue(v)
        newValueText = ""
    }
}

// MARK: - Simple flow layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
                         .reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowH = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowH + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxW = proposal.width ?? 0
        var rows: [[LayoutSubview]] = [[]]
        var rowW: CGFloat = 0
        for view in subviews {
            let w = view.sizeThatFits(.unspecified).width
            if rowW + w + (rows.last!.isEmpty ? 0 : spacing) > maxW, !rows.last!.isEmpty {
                rows.append([])
                rowW = 0
            }
            rows[rows.count - 1].append(view)
            rowW += w + (rows.last!.count > 1 ? spacing : 0)
        }
        return rows
    }
}
