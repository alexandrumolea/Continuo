import SwiftUI
import FirebaseAuth

struct HabitsView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm = HabitsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if vm.habits.isEmpty {
                            emptyState
                        } else {
                            ForEach(vm.habits) { habit in
                                HabitCard(habit: habit) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        vm.complete(habit)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        vm.delete(habit)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(ContinuoTheme.sunOrange)
                    }
                }
            }
            .sheet(isPresented: $vm.showAddSheet) {
                AddHabitSheet(vm: vm)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                if let uid = auth.firebaseUser?.uid { vm.start(userId: uid) }
            }
            .onDisappear { vm.stop() }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 14) {
                Text("⚡").font(.system(size: 44))
                Text("No habits yet.\nTap + to build your first routine.")
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

// MARK: - Habit card
struct HabitCard: View {
    let habit: Habit
    let onComplete: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                // Emoji
                Text(habit.emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(ContinuoTheme.background))

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.title)
                        .font(ContinuoTheme.rounded(15, weight: .medium))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .strikethrough(habit.isCompletedToday, color: ContinuoTheme.textMedium)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(habit.streak > 0 ? .orange : ContinuoTheme.textLight)
                        Text("\(habit.streak) day streak")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                }

                Spacer()

                // GP badge
                Text("+\(habit.gpReward) GP")
                    .font(ContinuoTheme.rounded(11, weight: .semibold))
                    .foregroundColor(ContinuoTheme.sunOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ContinuoTheme.sunOrange.opacity(0.12)))

                // Check button
                Button(action: onComplete) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(habit.isCompletedToday ? ContinuoTheme.olive : ContinuoTheme.charcoal.opacity(0.25))
                }
                .disabled(habit.isCompletedToday)
            }
        }
    }
}

// MARK: - Add habit sheet
struct AddHabitSheet: View {
    @ObservedObject var vm: HabitsViewModel
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("New Habit")
                    .font(ContinuoTheme.rounded(22, weight: .bold))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .padding(.top, 24)

                // Emoji picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pick an emoji")
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textMedium)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(vm.emojiOptions, id: \.self) { emoji in
                                Button {
                                    vm.newEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Circle()
                                                .fill(vm.newEmoji == emoji
                                                      ? ContinuoTheme.sunOrange.opacity(0.18)
                                                      : ContinuoTheme.charcoal.opacity(0.06))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(vm.newEmoji == emoji
                                                        ? ContinuoTheme.sunOrange
                                                        : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }

                // Title
                AuthField(icon: "pencil", placeholder: "Habit name…", text: $vm.newTitle)
                    .focused($focused)

                PrimaryButton(title: "Add Habit") { vm.addHabit() }
                    .disabled(vm.newTitle.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { focused = true }
    }
}

#Preview {
    HabitsView().environmentObject(AuthService())
}
