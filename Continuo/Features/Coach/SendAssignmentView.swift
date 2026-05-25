import SwiftUI

struct SendAssignmentView: View {
    let client: ContinuoUser
    let coachId: String

    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: AssignmentType = .reflection
    @State private var selectedRecurrence: RecurrenceType = .none
    @State private var hasExpiry = false
    @State private var expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var gpReward = 20
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

                    // Type picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Type").font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textMedium)
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 10) {
                            ForEach(AssignmentType.allCases, id: \.self) { type in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) { selectedType = type }
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(type.emoji)
                                        Text(type.label)
                                            .font(ContinuoTheme.rounded(13, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedType == type ? type.color.opacity(0.15) : Color.clear))
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedType == type ? type.color : ContinuoTheme.textLight.opacity(0.5), lineWidth: 1.5))
                                    .foregroundColor(selectedType == type ? type.color : ContinuoTheme.textMedium)
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

                    // Recurrence
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Frequency").font(ContinuoTheme.rounded(13)).foregroundColor(ContinuoTheme.textMedium)
                        HStack(spacing: 8) {
                            ForEach(RecurrenceType.allCases, id: \.self) { rec in
                                Button {
                                    withAnimation { selectedRecurrence = rec }
                                } label: {
                                    Text(rec.label)
                                        .font(ContinuoTheme.rounded(12, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedRecurrence == rec
                                                  ? ContinuoTheme.sunYellow.opacity(0.2)
                                                  : Color.clear))
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedRecurrence == rec
                                                    ? ContinuoTheme.sunYellow
                                                    : ContinuoTheme.textLight.opacity(0.4), lineWidth: 1.5))
                                        .foregroundColor(selectedRecurrence == rec
                                                         ? ContinuoTheme.terracotta
                                                         : ContinuoTheme.textMedium)
                                }
                            }
                        }
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
            type: selectedType,
            status: .active,
            recurrence: selectedRecurrence,
            gpReward: gpReward,
            expiresAt: hasExpiry ? expiryDate : nil,
            lastCompletedAt: nil,
            completionCount: 0,
            createdAt: Date()
        )
        do {
            try AssignmentService.shared.sendAssignment(assignment)
            withAnimation { didSend = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
        } catch {
            print("❌ sendAssignment: \(error)")
        }
        isSending = false
    }
}
