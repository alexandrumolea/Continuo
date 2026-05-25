import SwiftUI
import FirebaseAuth

struct TrackingView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm = TrackingViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                VStack(spacing: 0) {
                    segmentPicker
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if selectedTab == 0 {
                                objectivesSection
                            } else {
                                skillsSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { addButton }
            .sheet(isPresented: $vm.showAddObjective) {
                AddObjectiveSheet(vm: vm)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $vm.showAddSkill) {
                AddSkillSheet(vm: vm)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                if let uid = auth.firebaseUser?.uid { vm.start(userId: uid) }
            }
            .onDisappear { vm.stop() }
        }
    }

    // MARK: - Segment
    private var segmentPicker: some View {
        Picker("", selection: $selectedTab) {
            Text("Objectives").tag(0)
            Text("Skills").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Add button
    @ToolbarContentBuilder
    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                if selectedTab == 0 { vm.showAddObjective = true }
                else                { vm.showAddSkill = true }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(ContinuoTheme.sunOrange)
            }
        }
    }

    // MARK: - Objectives
    private var objectivesSection: some View {
        Group {
            if vm.objectives.isEmpty {
                emptyCard(emoji: "🎯", text: "No objectives yet.\nTap + to add one.")
            } else {
                ForEach(vm.objectives) { obj in
                    ObjectiveCard(objective: obj,
                                  onDecrement: { vm.stepObjective(obj, by: -0.1) },
                                  onIncrement: { vm.stepObjective(obj, by: +0.1) })
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { vm.deleteObjective(obj) }
                        label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    // MARK: - Skills
    private var skillsSection: some View {
        Group {
            if vm.skills.isEmpty {
                emptyCard(emoji: "🌱", text: "No skills yet.\nTap + to track a competency.")
            } else {
                ForEach(vm.skills) { skill in
                    SkillCard(skill: skill,
                              onDecrement: { vm.stepSkill(skill, by: -0.05) },
                              onIncrement: { vm.stepSkill(skill, by: +0.05) })
                }
            }
        }
    }

    private func emptyCard(emoji: String, text: String) -> some View {
        GlassCard {
            VStack(spacing: 14) {
                Text(emoji).font(.system(size: 44))
                Text(text)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.textMedium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .padding(.top, 40)
    }
}

// MARK: - Objective Card
struct ObjectiveCard: View {
    let objective: Objective
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    private var categoryColor: Color { Color(hex: objective.category.color) }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(objective.category.rawValue, systemImage: "")
                        .font(ContinuoTheme.rounded(11, weight: .semibold))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(categoryColor.opacity(0.12)))

                    Text(objective.category.emoji)
                    Spacer()
                    Text("\(Int(objective.progress * 100))%")
                        .font(ContinuoTheme.rounded(15, weight: .bold))
                        .foregroundColor(categoryColor)
                }

                Text(objective.title)
                    .font(ContinuoTheme.rounded(16, weight: .medium))
                    .foregroundColor(ContinuoTheme.charcoal)

                ContinuoProgressBar(progress: objective.progress, color: categoryColor)

                HStack {
                    Spacer()
                    stepButton(icon: "minus", action: onDecrement, disabled: objective.progress <= 0)
                    stepButton(icon: "plus",  action: onIncrement, disabled: objective.progress >= 1)
                }
            }
        }
    }

    private func stepButton(icon: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(Circle().fill(disabled
                                          ? ContinuoTheme.charcoal.opacity(0.06)
                                          : ContinuoTheme.sunOrange.opacity(0.14)))
                .foregroundColor(disabled ? ContinuoTheme.textLight : ContinuoTheme.sunOrange)
        }
        .disabled(disabled)
        .padding(.leading, 8)
    }
}

// MARK: - Skill Card
struct SkillCard: View {
    let skill: Skill
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(skill.name)
                        .font(ContinuoTheme.rounded(16, weight: .medium))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Spacer()
                    TierBadge(tier: skill.tier)
                }

                ContinuoProgressBar(progress: skill.progress, color: skill.tier.color)

                HStack {
                    Text("\(Int(skill.progress * 100))%")
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textMedium)
                    Spacer()
                    stepButton(icon: "minus", action: onDecrement, disabled: skill.progress <= 0)
                    stepButton(icon: "plus",  action: onIncrement, disabled: skill.progress >= 1)
                }
            }
        }
    }

    private func stepButton(icon: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(Circle().fill(disabled
                                          ? ContinuoTheme.charcoal.opacity(0.06)
                                          : skill.tier.color.opacity(0.14)))
                .foregroundColor(disabled ? ContinuoTheme.textLight : skill.tier.color)
        }
        .disabled(disabled)
        .padding(.leading, 8)
    }
}

// MARK: - Add Objective Sheet
struct AddObjectiveSheet: View {
    @ObservedObject var vm: TrackingViewModel
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("New Objective")
                    .font(ContinuoTheme.rounded(22, weight: .bold))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .padding(.top, 24)

                AuthField(icon: "target", placeholder: "Objective title…", text: $vm.newObjectiveTitle)
                    .focused($focused)

                // Category grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textMedium)
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 10) {
                        ForEach(ObjectiveCategory.allCases, id: \.self) { cat in
                            Button {
                                vm.newObjectiveCategory = cat
                            } label: {
                                HStack(spacing: 8) {
                                    Text(cat.emoji)
                                    Text(cat.rawValue)
                                        .font(ContinuoTheme.rounded(14, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(vm.newObjectiveCategory == cat
                                              ? Color(hex: cat.color).opacity(0.18)
                                              : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(vm.newObjectiveCategory == cat
                                                ? Color(hex: cat.color)
                                                : ContinuoTheme.charcoal.opacity(0.15), lineWidth: 1.5)
                                )
                                .foregroundColor(vm.newObjectiveCategory == cat
                                                 ? Color(hex: cat.color)
                                                 : ContinuoTheme.textMedium)
                            }
                        }
                    }
                }

                PrimaryButton(title: "Add Objective") { vm.addObjective() }
                    .disabled(vm.newObjectiveTitle.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { focused = true }
    }
}

// MARK: - Add Skill Sheet
struct AddSkillSheet: View {
    @ObservedObject var vm: TrackingViewModel
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("New Skill")
                    .font(ContinuoTheme.rounded(22, weight: .bold))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .padding(.top, 24)
                AuthField(icon: "bolt.fill", placeholder: "Skill name…", text: $vm.newSkillName)
                    .focused($focused)
                PrimaryButton(title: "Add Skill") { vm.addSkill() }
                    .disabled(vm.newSkillName.isEmpty)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { focused = true }
    }
}

#Preview {
    TrackingView().environmentObject(AuthService())
}
