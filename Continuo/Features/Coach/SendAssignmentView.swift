import SwiftUI

struct SendAssignmentView: View {
    let client: ContinuoUser
    let coachId: String

    @State private var title = ""
    @State private var description = ""
    @State private var selectedEmoji: String = "🎯"
    @State private var hasExpiry = false

    private let emojiOptions = [
        "🎯", "💪", "📖", "✍️", "🧘", "🏃",
        "💭", "🌱", "🔥", "⭐", "💡", "🌊",
        "🤝", "🧠", "❤️", "🎨", "🌿", "🔑",
        "🏆", "🌟", "🦁", "🗺️", "🌙", "✨"
    ]
    @State private var expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var gpReward = 20
    @State private var selectedCompetencyId: String? = nil
    @State private var isSending = false
    @State private var didSend = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Assignment")
                            .font(ContinuoTheme.rounded(24, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("For \(client.displayName)")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                    .padding(.top, 24)

                    // Emoji picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Emoji").font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textMedium)
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 10) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    HapticFeedback.selection()
                                    withAnimation(.easeInOut(duration: 0.1)) { selectedEmoji = emoji }
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 26))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedEmoji == emoji
                                                      ? ContinuoTheme.terracotta.opacity(0.15)
                                                      : Color.white.opacity(0.6))
                                                .overlay(RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedEmoji == emoji
                                                            ? ContinuoTheme.terracotta.opacity(0.4)
                                                            : Color(hex: "EDE8E0"), lineWidth: 1.5))
                                        )
                                }
                            }
                        }
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title").font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textMedium)
                        TextField("e.g. Morning reflection…", text: $title)
                            .font(ContinuoTheme.rounded(15))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .focused($titleFocused)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.8))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
                            )
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions / prompt")
                            .font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textMedium)
                        TextEditor(text: $description)
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.8))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "EDE8E0"), lineWidth: 1)))
                            .overlay(
                                Group {
                                    if description.isEmpty {
                                        Text("Describe what you want the client to do or reflect on…")
                                            .font(ContinuoTheme.rounded(14))
                                            .foregroundColor(ContinuoTheme.textLight)
                                            .padding(20)
                                            .allowsHitTesting(false)
                                    }
                                }, alignment: .topLeading
                            )
                    }

                    // GP Reward
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GP reward per completion")
                            .font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textMedium)
                        HStack {
                            Button { if gpReward > 5 { gpReward -= 5 } } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2).foregroundColor(ContinuoTheme.textLight)
                            }
                            Spacer()
                            Text("\(gpReward) GP")
                                .font(ContinuoTheme.rounded(22, weight: .bold))
                                .foregroundColor(ContinuoTheme.sunYellow)
                            Spacer()
                            Button { gpReward += 5 } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2).foregroundColor(ContinuoTheme.sunYellow)
                            }
                        }
                        .padding(.horizontal, 8)
                    }

                    // Expiry
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasExpiry) {
                            Text("Set expiry date")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                        .tint(ContinuoTheme.sunYellow)
                        if hasExpiry {
                            DatePicker("", selection: $expiryDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .accentColor(ContinuoTheme.sunYellow)
                        }
                    }

                    // Competency link (optional)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Link to competency (optional)")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textMedium)

                        FlowLayout(spacing: 8) {
                            ForEach(Competency.catalog) { competency in
                                let isSelected = selectedCompetencyId == competency.id
                                Button {
                                    HapticFeedback.selection()
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedCompetencyId = isSelected ? nil : competency.id
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(competency.emoji).font(.system(size: 13))
                                        Text(competency.name)
                                            .font(ContinuoTheme.rounded(12, weight: isSelected ? .semibold : .regular))
                                    }
                                    .foregroundColor(isSelected ? competency.color : ContinuoTheme.textMedium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? competency.color.opacity(0.12) : Color.white.opacity(0.6))
                                            .overlay(Capsule()
                                                .stroke(isSelected ? competency.color.opacity(0.5) : Color(hex: "EDE8E0"),
                                                        lineWidth: 1.5))
                                    )
                                }
                            }
                        }
                    }

                    // Send button
                    PrimaryButton(title: didSend ? "Sent! ✓" : "Send Assignment",
                                  isLoading: isSending) {
                        sendAssignment()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear { titleFocused = true }
    }

    private func sendAssignment() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              let clientId = client.id else { return }
        isSending = true
        let assignment = Assignment(
            coachId: coachId,
            clientId: clientId,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            emoji: selectedEmoji,
            status: .active,
            gpReward: gpReward,
            expiresAt: hasExpiry ? expiryDate : nil,
            lastCompletedAt: nil,
            completionCount: 0,
            createdAt: Date(),
            competencyId: selectedCompetencyId
        )
        do {
            try AssignmentService.shared.sendAssignment(assignment)
            HapticFeedback.success()
            withAnimation { didSend = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
        } catch {
            print("❌ sendAssignment: \(error)")
        }
        isSending = false
    }
}
