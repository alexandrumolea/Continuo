import SwiftUI

// MARK: - Assignment row — navigates to CoachAssignmentDetailView

struct CoachAssignmentRow: View {
    let assignment: Assignment
    let completions: [AssignmentCompletion]
    let clientName: String
    let onDelete: () -> Void

    @State private var showEdit = false

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 0) {

                // NavigationLink covers the main content area
                NavigationLink(destination: CoachAssignmentDetailView(
                    assignment: assignment,
                    completions: completions,
                    clientName: clientName
                )) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ContinuoTheme.terracotta.opacity(0.10))
                                .frame(width: 42, height: 42)
                            Text(assignment.emoji ?? "🎯").font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(assignment.title)
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 6) {
                                statusPill
                                if assignment.effectiveFrequency != .once { frequencyPill }
                                if !completions.isEmpty {
                                    Text("·").foregroundColor(ContinuoTheme.textLight)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10)).foregroundColor(ContinuoTheme.olive)
                                    Text("\(completions.count)× completed")
                                        .font(ContinuoTheme.rounded(11))
                                        .foregroundColor(ContinuoTheme.textMedium)
                                }
                            }

                            if !assignment.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(assignment.description)
                                    .font(ContinuoTheme.rounded(13))
                                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }

                            HStack(spacing: 10) {
                                Label("\(assignment.gpReward) GP", systemImage: "star.fill")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.sunOrange)
                                if let expiry = assignment.expiresAt {
                                    Label(expiry.formatted(date: .abbreviated, time: .omitted),
                                          systemImage: "calendar")
                                        .font(ContinuoTheme.rounded(11))
                                        .foregroundColor(ContinuoTheme.textLight)
                                }
                            }
                        }

                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundColor(ContinuoTheme.textLight).padding(.top, 2)
                    }
                }
                .buttonStyle(.plain)

                // Menu — sibling of NavigationLink
                Menu {
                    Button {
                        HapticFeedback.selection()
                        showEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        HapticFeedback.medium()
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ContinuoTheme.textLight)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AssignmentEditSheet(assignment: assignment)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Pills

    private var statusPill: some View {
        let (label, color): (String, Color) = {
            switch assignment.status {
            case .active:   return ("Active",   ContinuoTheme.olive)
            case .finished: return ("Finished", ContinuoTheme.sunOrange)
            case .paused:   return ("Paused",   ContinuoTheme.textLight)
            }
        }()
        return Text(label)
            .font(ContinuoTheme.rounded(10, weight: .semibold)).foregroundColor(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    // MARK: - Frequency pill

    private var frequencyPill: some View {
        let freq = assignment.effectiveFrequency
        let color: Color = {
            switch freq {
            case .daily:  return ContinuoTheme.olive
            case .weekly: return Color(hex: "7B5EA7")
            case .open:   return ContinuoTheme.sunOrange
            case .once:   return ContinuoTheme.textLight
            }
        }()
        return Label(freq.label, systemImage: freq.icon)
            .font(ContinuoTheme.rounded(10, weight: .semibold))
            .foregroundColor(color)
            .lineLimit(1).fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

// MARK: - Assignment edit sheet

private struct AssignmentEditSheet: View {
    let assignment: Assignment

    @State private var title: String
    @State private var description: String
    @State private var isSaving = false
    @FocusState private var focused: Int?
    @Environment(\.dismiss) private var dismiss

    init(assignment: Assignment) {
        self.assignment  = assignment
        _title       = State(initialValue: assignment.title)
        _description = State(initialValue: assignment.description)
    }

    private var hasChanges: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines) != assignment.title ||
        description.trimmingCharacters(in: .whitespacesAndNewlines) != assignment.description
    }
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasChanges
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                            TextField("Assignment title", text: $title)
                                .font(ContinuoTheme.rounded(15))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.9))
                                        .overlay(RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "EDE8E0"), lineWidth: 1.5))
                                )
                                .focused($focused, equals: 0)
                        }

                        // Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                            TextEditor(text: $description)
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .frame(minHeight: 120)
                                .focused($focused, equals: 1)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.9))
                                        .overlay(RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                focused == 1 ? ContinuoTheme.terracotta.opacity(0.5) : Color(hex: "EDE8E0"),
                                                lineWidth: 1.5))
                                )
                                .overlay(
                                    Group {
                                        if description.isEmpty {
                                            Text("Instructions for the client…")
                                                .font(ContinuoTheme.rounded(14))
                                                .foregroundColor(ContinuoTheme.textLight)
                                                .padding(20)
                                                .allowsHitTesting(false)
                                        }
                                    }, alignment: .topLeading
                                )
                        }

                        PrimaryButton(title: isSaving ? "Saving…" : "Save changes", isLoading: isSaving) {
                            save()
                        }
                        .disabled(!canSave || isSaving)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        Task {
            try? await AssignmentService.shared.updateAssignment(
                assignment,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            await MainActor.run {
                HapticFeedback.success()
                dismiss()
            }
        }
    }
}
