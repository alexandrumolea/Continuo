import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

// MARK: - Growth tier (unchanged)

struct GrowthTier: Identifiable {
    let id = UUID()
    let name: String
    let minGP: Int
    let maxGP: Int
    let description: String
    let color: Color
    let imageName: String
}

// MARK: - View model

@MainActor
final class GrowthViewModel: ObservableObject {

    // MARK: Badge state
    @Published var earnedBadgeDates: [String: Date] = [:]   // badgeId → date earned
    private var badgesReg: ListenerRegistration?

    var earnedBadgeIds: Set<String> { Set(earnedBadgeDates.keys) }

    // Returns the first badge in a series that is not yet earned (the "next up" one)
    func nextBadge(for category: BadgeCategory) -> BadgeDefinition? {
        BadgeService.catalog
            .filter { $0.category == category }
            .first { !earnedBadgeIds.contains($0.id) }
    }

    // Progress fraction (0…1) toward a given badge
    func progress(for badge: BadgeDefinition,
                  practiceCount: Int,
                  coachingCount: Int,
                  maxCompetencyScore: Int) -> Double {
        let value: Int
        switch badge.category {
        case .practice:   value = practiceCount
        case .coaching:   value = coachingCount
        case .competency: value = maxCompetencyScore
        }
        return min(1.0, Double(value) / Double(badge.threshold))
    }

    // True when every badge in a category is earned
    func allEarned(for category: BadgeCategory) -> Bool {
        BadgeService.catalog
            .filter { $0.category == category }
            .allSatisfy { earnedBadgeIds.contains($0.id) }
    }

    // MARK: - Listener management

    func startBadgesListener(userId: String) {
        guard badgesReg == nil else { return }
        badgesReg = BadgeService.shared.earnedBadgesListener(userId: userId) { [weak self] dict in
            self?.earnedBadgeDates = dict
        }
    }

    func stopBadgesListener() {
        badgesReg?.remove()
        badgesReg = nil
    }

    // MARK: - Tiers

    let tiers: [GrowthTier] = [
        GrowthTier(
            name: "Waking",
            minGP: 0,    maxGP: 200,
            description: "Something is waking up in you. You feel a pull toward growth but haven't yet named it.",
            color: Color(hex: "7B9CB8"), imageName: "OwlWaking"
        ),
        GrowthTier(
            name: "Seeking",
            minGP: 200,  maxGP: 450,
            description: "You're asking the real questions. You're willing to look honestly at yourself.",
            color: Color(hex: "C4873A"), imageName: "OwlSeeking"
        ),
        GrowthTier(
            name: "Emerging",
            minGP: 450,  maxGP: 700,
            description: "Layers are falling away. You're discovering who you are beneath the noise.",
            color: Color(hex: "4E7040"), imageName: "OwlEmerging"
        ),
        GrowthTier(
            name: "Aligned",
            minGP: 700,  maxGP: 2500,
            description: "Your actions reflect your values. You live with intention, not reaction.",
            color: Color(hex: "2D9B8A"), imageName: "OwlAligned"
        ),
        GrowthTier(
            name: "Flourishing",
            minGP: 2500, maxGP: 5000,
            description: "You're in full expression. Growth feels natural, not forced.",
            color: Color(hex: "C4A020"), imageName: "OwlFlourishing"
        ),
        GrowthTier(
            name: "Sage",
            minGP: 5000, maxGP: Int.max,
            description: "You carry wisdom lightly. Your presence itself is the gift.",
            color: Color(hex: "7B5EA7"), imageName: "OwlSage"
        ),
    ]

    func currentTier(gp: Int) -> GrowthTier {
        tiers.last(where: { gp >= $0.minGP }) ?? tiers[0]
    }

    func currentTierIndex(gp: Int) -> Int {
        tiers.lastIndex(where: { gp >= $0.minGP }) ?? 0
    }

    func tierProgress(gp: Int) -> Double {
        let tier = currentTier(gp: gp)
        guard tier.maxGP != Int.max else { return 1.0 }
        return max(0, min(1, Double(gp - tier.minGP) / Double(tier.maxGP - tier.minGP)))
    }

    func gpToNextTier(gp: Int) -> Int {
        let tier = currentTier(gp: gp)
        guard tier.maxGP != Int.max else { return 0 }
        return max(0, tier.maxGP - gp)
    }
}
