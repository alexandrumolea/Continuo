import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var events: [JourneyEvent] = []
    @Published var assignments: [Assignment] = []
    @Published var completedPracticeIds: Set<String> = []
    @Published var mindfulnessMinutesToday: Int = 0
    @Published var goals: [Goal] = []
    @Published var coachingSessions: [CoachingSession] = []

    private var journeyReg: ListenerRegistration?
    private var assignmentReg: ListenerRegistration?
    private var practiceReg: ListenerRegistration?
    private var mindfulnessReg: ListenerRegistration?
    private var goalReg: ListenerRegistration?
    private var sessionsReg: ListenerRegistration?
    private var activeUserId: String?

    // Called every time HomeView appears — only creates persistent listeners once per userId
    func start(userId: String, isClient: Bool) {
        // Journey listener: always recreate (lightweight, single-field query)
        journeyReg?.remove()
        journeyReg = FirestoreService.shared.journeyListener(userId: userId) { [weak self] in
            self?.events = $0
        }

        // If userId already active, still check whether client listeners need to be created
        // (profile may have loaded after the first onAppear call)
        if activeUserId == userId {
            if isClient && assignmentReg == nil {
                assignmentReg = AssignmentService.shared.clientAssignmentsListener(clientId: userId) { [weak self] in
                    self?.assignments = $0
                }
            }
            if isClient && practiceReg == nil {
                practiceReg = DailyPracticeService.shared.completedTodayListener(userId: userId) { [weak self] in
                    self?.completedPracticeIds = $0
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
            practiceReg = DailyPracticeService.shared.completedTodayListener(userId: userId) { [weak self] in
                self?.completedPracticeIds = $0
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

    // Called in onDisappear — only pauses the journey listener
    func stop() {
        journeyReg?.remove()
        journeyReg = nil
        // Assignment / practice / goal listeners stay alive until userId changes or deinit
    }

    deinit {
        journeyReg?.remove()
        assignmentReg?.remove()
        practiceReg?.remove()
        mindfulnessReg?.remove()
        goalReg?.remove()
        sessionsReg?.remove()
    }
}
