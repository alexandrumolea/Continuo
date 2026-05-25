import SwiftUI
import FirebaseFirestore

struct MyPassionsDetailView: View {
    let userId: String

    @State private var passions: [PersonalPassion] = []
    @State private var listener: ListenerRegistration?
    @State private var newPassionText = ""
    @FocusState private var inputFocused: Bool

    private let color = Color(hex: "C4536A")
    private let guidingQuestions = [
        "What could you do all day and not get tired or bored?",
        "How would you spend your time if you already had all the money you needed?"
    ]

    private var canAdd: Bool {
        !newPassionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🔥")
                            .font(.system(size: 44))
                        Text("My Passions")
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("No limit — add as many as you have")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(color.opacity(0.7))
                    }
                    .padding(.top, 4)

                    // ── Current passions ──
                    if !passions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Your passions")
                                    .font(ContinuoTheme.rounded(15, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                Spacer()
                                Text("\(passions.count) total")
                                    .font(ContinuoTheme.rounded(12))
                                    .foregroundColor(color)
                            }

                            FlowLayout(spacing: 10) {
                                ForEach(passions) { passion in
                                    passionChip(passion)
                                }
                            }
                        }
                    }

                    // ── Add passion ──
                    VStack(alignment: .leading, spacing: 8) {
                        Text(passions.isEmpty ? "Add your first passion" : "Add another passion")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)

                        HStack(spacing: 10) {
                            TextField("e.g. Photography, Teaching, Rock climbing…", text: $newPassionText)
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .focused($inputFocused)
                                .submitLabel(.done)
                                .onSubmit { addPassion() }
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

                            Button(action: addPassion) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(canAdd ? color : ContinuoTheme.textLight)
                            }
                            .disabled(!canAdd)
                        }
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
            listener = PersonalPassionsService.shared.passionsListener(userId: userId) { passions = $0 }
        }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Passion chip

    private func passionChip(_ passion: PersonalPassion) -> some View {
        HStack(spacing: 6) {
            Text(passion.text)
                .font(ContinuoTheme.rounded(14, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)

            Button {
                Task { try? await PersonalPassionsService.shared.deletePassion(passion) }
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

    private func addPassion() {
        let text = newPassionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let p = PersonalPassion(userId: userId, text: text, createdAt: Date())
        try? PersonalPassionsService.shared.addPassion(p)
        newPassionText = ""
    }
}
