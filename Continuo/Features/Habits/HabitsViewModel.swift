import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class HabitsViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var showAddSheet = false
    @Published var newTitle = ""
    @Published var newEmoji = "⚡"

    private var userId: String = ""
    private var listener: ListenerRegistration?
    private let fs = FirestoreService.shared

    let emojiOptions = ["⚡", "📚", "🏃", "💧", "🧘", "🎯", "🌅", "💪", "✍️", "🥗"]

    func start(userId: String) {
        self.userId = userId
        listener?.remove()
        listener = fs.habitsListener(userId: userId) { [weak self] items in
            self?.habits = items
        }
    }

    func stop() { listener?.remove() }

    // MARK: - Complete habit
    func complete(_ habit: Habit) {
        guard !habit.isCompletedToday else { return }
        Task {
            try? await fs.completeHabit(habit)
            let event = JourneyEvent(
                userId: userId,
                type: .habitCompleted,
                title: habit.emoji + " " + habit.title,
                subtitle: "Streak: \(habit.streak + 1) day\(habit.streak + 1 == 1 ? "" : "s") 🔥",
                gpEarned: habit.gpReward,
                createdAt: Date()
            )
            try? fs.awardGP(userId: userId, amount: habit.gpReward, event: event)
        }
    }

    // MARK: - Add habit
    func addHabit() {
        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let habit = Habit(
            userId: userId,
            title: newTitle.trimmingCharacters(in: .whitespaces),
            emoji: newEmoji,
            streak: 0,
            lastCompleted: nil,
            gpReward: 10
        )
        try? fs.addHabit(habit)
        newTitle = ""
        newEmoji = "⚡"
        showAddSheet = false
    }

    // MARK: - Delete habit
    func delete(_ habit: Habit) {
        Task { try? await fs.deleteHabit(habit) }
    }
}
