import SwiftUI
import FirebaseFirestore

struct MySkillsDetailView: View {
    let userId: String

    @State private var skills: [PersonalSkill] = []
    @State private var listener: ListenerRegistration?
    @State private var newSkillText = ""
    @FocusState private var inputFocused: Bool

    private let color = Color(hex: "2E7DD1")
    private let guidingQuestions = [
        "What abilities did you develop over time?",
        "What do you do better than most in your domain?",
        "What have you practiced most and now do it easier than others?"
    ]

    private var canAdd: Bool {
        !newSkillText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🛠️")
                            .font(.system(size: 44))
                        Text("My Skills")
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("No limit — add as many as you have")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(color.opacity(0.7))
                    }
                    .padding(.top, 4)

                    // ── Current skills ──
                    if !skills.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Your skills")
                                    .font(ContinuoTheme.rounded(15, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                Spacer()
                                Text("\(skills.count) total")
                                    .font(ContinuoTheme.rounded(12))
                                    .foregroundColor(color)
                            }

                            FlowLayout(spacing: 10) {
                                ForEach(skills) { skill in
                                    skillChip(skill)
                                }
                            }
                        }
                    }

                    // ── Add skill ──
                    VStack(alignment: .leading, spacing: 8) {
                        Text(skills.isEmpty ? "Add your first skill" : "Add another skill")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)

                        HStack(spacing: 10) {
                            TextField("e.g. Public speaking, Data analysis…", text: $newSkillText)
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .focused($inputFocused)
                                .submitLabel(.done)
                                .onSubmit { addSkill() }
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

                            Button(action: addSkill) {
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
            listener = PersonalSkillsService.shared.skillsListener(userId: userId) { skills = $0 }
        }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Skill chip

    private func skillChip(_ skill: PersonalSkill) -> some View {
        HStack(spacing: 6) {
            Text(skill.text)
                .font(ContinuoTheme.rounded(14, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)

            Button {
                Task { try? await PersonalSkillsService.shared.deleteSkill(skill) }
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

    private func addSkill() {
        let text = newSkillText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let s = PersonalSkill(userId: userId, text: text, createdAt: Date())
        try? PersonalSkillsService.shared.addSkill(s)
        newSkillText = ""
    }
}
