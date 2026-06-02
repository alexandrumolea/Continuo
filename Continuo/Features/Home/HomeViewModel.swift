import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var events: [JourneyEvent] = []
    @Published var assignments: [Assignment] = []
    /// Realtime completions for today (kept updated by the Firestore listener)
    @Published var completedPracticeIds: Set<String> = []
    /// Completions for the currently selected calendar date (today → same as completedPracticeIds)
    @Published var completedIdsForSelectedDate: Set<String> = []
    @Published var mindfulnessMinutesToday: Int = 0
    @Published var goals: [Goal] = []
    @Published var coachingSessions: [CoachingSession] = []

    /// The date the user has selected in the calendar strip (drives Thread + practice card state)
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date()) {
        didSet { Task { await refreshSelectedDateCompletions() } }
    }

    var isViewingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var journeyReg: ListenerRegistration?
    private var assignmentReg: ListenerRegistration?
    private var practiceReg: ListenerRegistration?
    private var mindfulnessReg: ListenerRegistration?
    private var goalReg: ListenerRegistration?
    private var sessionsReg: ListenerRegistration?
    private var activeUserId: String?
    /// The dateKey the practiceReg listener was created for — used to detect day rollover
    private var practiceListenerDateKey: String = ""

    // Called every time HomeView appears AND when the app returns to foreground
    func start(userId: String, isClient: Bool) {
        // Journey listener: always recreate (lightweight)
        journeyReg?.remove()
        journeyReg = FirestoreService.shared.journeyListener(userId: userId) { [weak self] in
            self?.events = $0
        }

        let today = todayKey()

        if activeUserId == userId {
            if isClient && assignmentReg == nil {
                assignmentReg = AssignmentService.shared.clientAssignmentsListener(clientId: userId) { [weak self] in
                    self?.assignments = $0
                }
            }
            // Recreate practice listener if not yet created OR if the day has rolled over
            if isClient && (practiceReg == nil || practiceListenerDateKey != today) {
                practiceReg?.remove()
                practiceListenerDateKey = today
                practiceReg = DailyPracticeService.shared.completedTodayListener(userId: userId) { [weak self] ids in
                    guard let self else { return }
                    self.completedPracticeIds = ids
                    if self.isViewingToday { self.completedIdsForSelectedDate = ids }
                }
            }
            if isClient && mindfulnessReg == nil {
                mindfulnessReg = DailyPracticeService.shared.mindfulnessTodayListener(userId: userId) { [weak self] in
                    self?.mindfulnessMinutesToday = $0
                }
            }
            if isClient && sessionsReg == nil {
                sessionsReg = CoachingSessionService.shared.sessionsListener(userId: userId) { [weak self] in
                    self?.coachingSessions = $0
                }
            }
            return
        }

        // First time for this userId — create all persistent listeners
        activeUserId = userId

        goalReg?.remove()
        goalReg = GoalService.shared.goalsListener(userId: userId) { [weak self] in
            self?.goals = $0
        }

        if isClient {
            assignmentReg?.remove()
            assignmentReg = AssignmentService.shared.clientAssignmentsListener(clientId: userId) { [weak self] in
                self?.assignments = $0
            }
            practiceReg?.remove()
            practiceListenerDateKey = today
            practiceReg = DailyPracticeService.shared.completedTodayListener(userId: userId) { [weak self] ids in
                guard let self else { return }
                self.completedPracticeIds = ids
                if self.isViewingToday { self.completedIdsForSelectedDate = ids }
            }
            mindfulnessReg?.remove()
            mindfulnessReg = DailyPracticeService.shared.mindfulnessTodayListener(userId: userId) { [weak self] in
                self?.mindfulnessMinutesToday = $0
            }
            sessionsReg?.remove()
            sessionsReg = CoachingSessionService.shared.sessionsListener(userId: userId) { [weak self] in
                self?.coachingSessions = $0
            }
        }
    }

    func stop() {
        journeyReg?.remove()
        journeyReg = nil
    }

    deinit {
        journeyReg?.remove()
        assignmentReg?.remove()
        practiceReg?.remove()
        mindfulnessReg?.remove()
        goalReg?.remove()
        sessionsReg?.remove()
    }

    // MARK: - Private helpers

    private func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func refreshSelectedDateCompletions() async {
        guard let userId = activeUserId else { return }
        if isViewingToday {
            completedIdsForSelectedDate = completedPracticeIds
        } else {
            completedIdsForSelectedDate = await DailyPracticeService.shared.fetchCompletions(userId: userId, date: selectedDate)
        }
    }
}
