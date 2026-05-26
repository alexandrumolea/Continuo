import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class TrackingViewModel: ObservableObject {
    @Published var objectives: [Objective] = []
    @Published var skills: [Skill] = []
    @Published var showAddObjective = false
    @Published var showAddSkill = false

    // Add objective form
    @Published var newObjectiveTitle = ""
    @Published var newObjectiveCategory: ObjectiveCategory = .personal

    // Add skill form
    @Published var newSkillName = ""

    private var userId: String = ""
    private var objectivesListener: ListenerRegistration?
    private var skillsListener: ListenerRegistration?
    private let fs = FirestoreService.shared

    func start(userId: String) {
        self.userId = userId
        objectivesListener?.remove()
        skillsListener?.remove()

        objectivesListener = fs.objectivesListener(userId: userId) { [weak self] items in
            self?.objectives = items
        }
        skillsListener = fs.skillsListener(userId: userId) { [weak self] items in
            self?.skills = items
        }
    }

    func stop() {
        objectivesListener?.remove()
        skillsListener?.remove()
    }

    // MARK: - Objective progress (step = ±0.1)
    func stepObjective(_ objective: Objective, by delta: Double) {
        let newProgress = max(0, min(1, objective.progress + delta))
        Task {
            try? await fs.updateObjectiveProgress(objective, progress: newProgress)
            if newProgress == 1.0 && objective.progress < 1.0 {
                let event = JourneyEvent(
                    userId: userId,
                    type: .objectiveUpdated,
                    title: "Objective complete: \(objective.title)",
                    subtitle: objective.category.emoji + " " + objective.category.rawValue,
                    gpEarned: 30,
                    createdAt: Date()
                )
                try? fs.awardGP(userId: userId, amount: 30, event: event)
            }
        }
    }

    func deleteObjective(_ obj: Objective) {
        Task { try? await fs.deleteObjective(obj) }
    }

    func addObjective() {
        guard !newObjectiveTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let obj = Objective(
            userId: userId,
            title: newObjectiveTitle.trimmingCharacters(in: .whitespaces),
            category: newObjectiveCategory,
            progress: 0,
            createdAt: Date()
        )
        try? fs.addObjective(obj)
        newObjectiveTitle = ""
        showAddObjective = false

        // Setting a new objective sharpens Agency (+5 pts)
        Task {
            try? await CompetencyService.shared.addPoints(
                userId: userId,
                competencyId: "agency",
                points: 5
            )
        }
    }

    // MARK: - Skill progress (step = ±0.05)
    func stepSkill(_ skill: Skill, by delta: Double) {
        let previousTier = skill.tier
        let newProgress = max(0, min(1, skill.progress + delta))

        // Compute what new tier would be
        var temp = skill; temp.progress = newProgress
        let newTier = temp.tier

        Task {
            try? await fs.updateSkillProgress(skill, progress: newProgress)
            if newTier != previousTier && delta > 0 {
                let event = JourneyEvent(
                    userId: userId,
                    type: .skillLevelUp,
                    title: "\(skill.name) reached \(newTier.rawValue)",
                    subtitle: "Skill level up 🎯",
                    gpEarned: newTier.gpBonus,
                    createdAt: Date()
                )
                try? fs.awardGP(userId: userId, amount: newTier.gpBonus, event: event)
            }
        }
    }

    func addSkill() {
        guard !newSkillName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let skill = Skill(
            userId: userId,
            name: newSkillName.trimmingCharacters(in: .whitespaces),
            progress: 0,
            createdAt: Date()
        )
        try? fs.addSkill(skill)
        newSkillName = ""
        showAddSkill = false
    }
}
