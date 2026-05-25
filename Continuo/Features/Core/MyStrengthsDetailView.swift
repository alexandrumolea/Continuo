import SwiftUI
import FirebaseFirestore

struct MyStrengthsDetailView: View {
    let userId: String

    @State private var strengths: [PersonalStrength] = []
    @State private var listener: ListenerRegistration?
    @State private var newStrengthText = ""
    @FocusState private var inputFocused: Bool

    private let maxItems = 5
    private let color = ContinuoTheme.olive
    private let guidingQuestions = [
        "What are your top 5 strengths?",
        "What were you appreciated for when you were a child?",
        "What do others appreciate about you that you do effortlessly?"
    ]

    private var canAdd: Bool {
        strengths.count < maxItems &&
        !newStrengthText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("💪")
                            .font(.system(size: 44))
                        Text("My Strengths")
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("Up to \(maxItems) personal strengths")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(color.opacity(0.7))
                    }
                    .padding(.top, 4)

                    // ── Current strengths ──
                    if !strengths.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your strengths")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)

                            FlowLayout(spacing: 10) {
                                ForEach(strengths) { strength in
                                    strengthChip(strength)
                                }
                            }
                        }
                    }

                    // ── Add strength ──
                    if strengths.count < maxItems {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(strengths.isEmpty ? "Add your first strength" : "Add another strength")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)

                            HStack(spacing: 10) {
                                TextField("e.g. Empathy, Leadership, Creativity…", text: $newStrengthText)
                                    .font(ContinuoTheme.rounded(14))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .focused($inputFocused)
                                    .submitLabel(.done)
                                    .onSubmit { addStrength() }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.88))
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    inputFocused
                                                        ? color.opacity(0.5)
                                                        : Color(hex: "EDE8E0"),
                                                    lineWidth: 1.5
                                                ))
                                    )

                                Button(action: addStrength) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(canAdd ? color : ContinuoTheme.textLight)
                                }
                                .disabled(!canAdd)
                            }

                            Text("\(maxItems - strengths.count) remaining")
                                .font(ContinuoTheme.rounded(11))
                                .foregroundColor(ContinuoTheme.textLight)
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(color)
                                .font(.title3)
                            Text("You've identified all 5 strengths.\nDelete one to add another.")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14)
                            .fill(color.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(color.opacity(0.22), lineWidth: 1)))
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
                                        .fill(color)
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
                                    .fill(color.opacity(0.06))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(color.opacity(0.18), lineWidth: 1))
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            listener = StrengthsService.shared.strengthsListener(userId: userId) { strengths = $0 }
        }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Strength chip
    private func strengthChip(_ strength: PersonalStrength) -> some View {
        HStack(spacing: 6) {
            Text(strength.text)
                .font(ContinuoTheme.rounded(14, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)

            Button {
                Task { try? await StrengthsService.shared.deleteStrength(strength) }
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
                .fill(color.opacity(0.09))
                .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
        )
    }

    // MARK: - Add
    private func addStrength() {
        let text = newStrengthText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, strengths.count < maxItems else { return }
        let s = PersonalStrength(userId: userId, text: text, createdAt: Date())
        try? StrengthsService.shared.addStrength(s)
        newStrengthText = ""
    }
}
