import SwiftUI
import FirebaseFirestore

struct GoalDetailView: View {
    let goal: Goal
    let userId: String

    @State private var progressDraft: Double
    @State private var successDraft: String
    @State private var successSaveTask: DispatchWorkItem?
    @State private var reflections: [GoalReflection] = []
    @State private var reflectionListener: ListenerRegistration?
    @State private var showAddReflection = false
    @State private var newReflectionText = ""
    @State private var isSavingReflection = false
    @State private var saveTask: DispatchWorkItem?
    // Edit reflection
    @State private var editingReflection: GoalReflection? = nil
    @State private var editReflectionText = ""
    // Edit goal
    @State private var showEditSheet = false
    @State private var editTitle = ""
    @State private var editType: GoalType = .general
    // Delete goal
    @State private var showDeleteAlert = false
    @FocusState private var reflectionFocused: Bool
    @FocusState private var editTitleFocused: Bool
    @FocusState private var successFocused: Bool
    @FocusState private var editReflectionFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(goal: Goal, userId: String) {
        self.goal = goal
        self.userId = userId
        _progressDraft = State(initialValue: goal.progress)
        _successDraft  = State(initialValue: goal.successMeasure ?? "")
    }

    private var progressPercent: Int { Int((progressDraft * 100).rounded()) }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    headerCard

                    // Success measure
                    successMeasureCard

                    // Progress
                    progressCard

                    // Reflections
                    reflectionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle(goal.type.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        editTitle = goal.title
                        editType  = goal.type
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.body.weight(.medium))
                            .foregroundColor(goal.type.color)
                    }
                    Button { showDeleteAlert = true } label: {
                        Image(systemName: "trash")
                            .font(.body.weight(.medium))
                            .foregroundColor(ContinuoTheme.terracotta)
                    }
                    Button { showAddReflection = true } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundColor(goal.type.color)
                    }
                }
            }
        }
        .alert("Delete goal?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await GoalService.shared.deleteGoal(goal)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(goal.title)\" and all its reflections.")
        }
        .sheet(isPresented: $showAddReflection) {
            addReflectionSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditSheet) {
            editGoalSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingReflection) { reflection in
            editReflectionSheet(reflection)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            guard let id = goal.id else { return }
            reflectionListener = GoalService.shared.reflectionsListener(goalId: id) {
                reflections = $0
            }
        }
        .onDisappear {
            reflectionListener?.remove()
            saveTask?.cancel()
            // Flush any pending progress save immediately
            if goal.id != nil {
                Task { try? await GoalService.shared.updateProgress(goal, progress: progressDraft) }
            }
        }
    }

    // MARK: - Header card
    private var headerCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(goal.type.cardColor)
                        .frame(width: 56, height: 56)
                    Text(goal.type.emoji)
                        .font(.system(size: 28))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(ContinuoTheme.rounded(18, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(goal.type.label)
                        .font(ContinuoTheme.rounded(11, weight: .semibold))
                        .foregroundColor(goal.type.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(goal.type.color.opacity(0.1)))
                }
                Spacer()
            }
        }
    }

    // MARK: - Progress card
    private var progressCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Progress")
                        .font(ContinuoTheme.rounded(14, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Spacer()
                    Text("\(progressPercent)%")
                        .font(ContinuoTheme.rounded(28, weight: .bold))
                        .foregroundColor(goal.type.color)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: progressPercent)
                }

                // Slider
                Slider(value: $progressDraft, in: 0...1, step: 0.01)
                    .tint(goal.type.color)
                    .onChange(of: progressDraft) { _, _ in
                        scheduleProgressSave()
                    }

                if progressPercent == 100 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(ContinuoTheme.olive)
                        Text("Goal achieved! 🎉")
                            .font(ContinuoTheme.rounded(13, weight: .semibold))
                            .foregroundColor(ContinuoTheme.olive)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }

    // MARK: - Reflections section
    private var reflectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reflections")
                    .font(ContinuoTheme.rounded(20, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Spacer()
                Button { showAddReflection = true } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(ContinuoTheme.rounded(13, weight: .medium))
                        .foregroundColor(goal.type.color)
                }
            }

            if reflections.isEmpty {
                GlassCard {
                    VStack(spacing: 10) {
                        Text("💭").font(.system(size: 32))
                        Text("No reflections yet.\nTap + to add your first one.")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textMedium)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(reflections.enumerated()), id: \.element.id) { idx, reflection in
                        reflectionRow(reflection, isLast: idx == reflections.count - 1)
                    }
                }
            }
        }
    }

    private func reflectionRow(_ reflection: GoalReflection, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot + line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(goal.type.color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "text.bubble.fill")
                        .font(.caption2)
                        .foregroundColor(goal.type.color)
                }
                if !isLast {
                    Rectangle()
                        .fill(ContinuoTheme.charcoal.opacity(0.08))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(reflection.text)
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text(reflection.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(ContinuoTheme.textLight)
                    Text("· +5 GP")
                        .font(ContinuoTheme.rounded(10, weight: .semibold))
                        .foregroundColor(ContinuoTheme.sunOrange)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, isLast ? 0 : 20)

            Spacer()

            Menu {
                Button {
                    editingReflection = reflection
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    guard let goalId = goal.id else { return }
                    Task { try? await GoalService.shared.deleteReflection(reflection, goalId: goalId) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundColor(ContinuoTheme.textLight)
                    .padding(8)
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Success measure card
    private var successMeasureCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal")
                        .font(.subheadline)
                        .foregroundColor(goal.type.color)
                    Text("How do you measure success?")
                        .font(ContinuoTheme.rounded(14, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                }

                ZStack(alignment: .topLeading) {
                    if successDraft.isEmpty {
                        Text("Describe what success looks like for this goal…")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textLight)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $successDraft)
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .frame(minHeight: 80)
                        .focused($successFocused)
                        .scrollContentBackground(.hidden)
                        .onChange(of: successDraft) { _, _ in scheduleSuccessSave() }
                }

                if successFocused {
                    HStack {
                        Spacer()
                        Button("Done") { successFocused = false }
                            .font(ContinuoTheme.rounded(13, weight: .semibold))
                            .foregroundColor(goal.type.color)
                    }
                }
            }
        }
    }

    // MARK: - Edit reflection sheet
    private func editReflectionSheet(_ reflection: GoalReflection) -> some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit Reflection")
                    .font(ContinuoTheme.rounded(20, weight: .bold))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .padding(.top, 8)

                TextEditor(text: $editReflectionText)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .frame(minHeight: 130)
                    .focused($editReflectionFocused)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.88))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(goal.type.color.opacity(0.35), lineWidth: 1.5)))

                PrimaryButton(title: "Save", isLoading: false) {
                    let text = editReflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty, let goalId = goal.id else { return }
                    Task { try? await GoalService.shared.updateReflection(reflection, goalId: goalId, text: text) }
                    editingReflection = nil
                }
                .disabled(editReflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            editReflectionText = reflection.text
            editReflectionFocused = true
        }
    }

    // MARK: - Edit goal sheet
    private var editGoalSheet: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                Text("Edit Goal")
                    .font(ContinuoTheme.rounded(22, weight: .bold))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .padding(.top, 8)

                // Type picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(ContinuoTheme.rounded(13, weight: .semibold))
                        .foregroundColor(ContinuoTheme.textMedium)
                    HStack(spacing: 10) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Button {
                                editType = type
                            } label: {
                                HStack(spacing: 6) {
                                    Text(type.emoji)
                                    Text(type.label)
                                        .font(ContinuoTheme.rounded(13, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(editType == type ? type.color.opacity(0.15) : Color.white.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(editType == type ? type.color : Color.clear, lineWidth: 1.5)
                                        )
                                )
                                .foregroundColor(editType == type ? type.color : ContinuoTheme.textMedium)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(ContinuoTheme.rounded(13, weight: .semibold))
                        .foregroundColor(ContinuoTheme.textMedium)
                    TextField("Goal title", text: $editTitle)
                        .font(ContinuoTheme.rounded(15))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .focused($editTitleFocused)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.88))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(editType.color.opacity(0.35), lineWidth: 1.5))
                        )
                }

                Spacer()

                PrimaryButton(title: "Save Changes", isLoading: false) {
                    let trimmed = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    Task { try? await GoalService.shared.updateGoal(goal, title: trimmed, type: editType) }
                    showEditSheet = false
                }
                .disabled(editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear { editTitleFocused = true }
    }

    // MARK: - Add reflection sheet
    private var addReflectionSheet: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("Add Reflection")
                    .font(ContinuoTheme.rounded(20, weight: .bold))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .padding(.top, 8)

                TextEditor(text: $newReflectionText)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .frame(minHeight: 130)
                    .focused($reflectionFocused)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.88))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(goal.type.color.opacity(0.35), lineWidth: 1.5)))
                    .overlay(
                        Group {
                            if newReflectionText.isEmpty {
                                Text("What's on your mind about this goal?")
                                    .font(ContinuoTheme.rounded(14))
                                    .foregroundColor(ContinuoTheme.textLight)
                                    .padding(20)
                                    .allowsHitTesting(false)
                            }
                        }, alignment: .topLeading
                    )

                PrimaryButton(
                    title: isSavingReflection ? "Saving…" : "Save Reflection",
                    isLoading: isSavingReflection
                ) {
                    saveReflection()
                }
                .disabled(newReflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear { reflectionFocused = true }
    }

    // MARK: - Helpers
    private func scheduleSuccessSave() {
        successSaveTask?.cancel()
        let task = DispatchWorkItem {
            Task { try? await GoalService.shared.updateSuccessMeasure(self.goal, text: self.successDraft) }
        }
        successSaveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: task)
    }

    private func scheduleProgressSave() {
        saveTask?.cancel()
        let task = DispatchWorkItem {
            Task { try? await GoalService.shared.updateProgress(self.goal, progress: self.progressDraft) }
        }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: task)
    }

    private func saveReflection() {
        let text = newReflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let goalId = goal.id else { return }
        isSavingReflection = true
        let reflection = GoalReflection(goalId: goalId, userId: userId,
                                         text: text, createdAt: Date())
        do {
            try GoalService.shared.addReflection(reflection, goalId: goalId)
            newReflectionText = ""
            showAddReflection = false
        } catch {
            print("❌ addReflection: \(error)")
        }
        isSavingReflection = false
    }
}
