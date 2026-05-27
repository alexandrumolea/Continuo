import Foundation
import Combine
import SwiftUI

struct GrowthTier: Identifiable {
    let id = UUID()
    let name: String
    let minGP: Int
    let maxGP: Int
    let description: String   // who you are when you've arrived here
    let color: Color
    let imageName: String     // asset name for this level's owl
}

struct Badge: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let description: String
    let requiredGP: Int
    var isUnlocked: Bool
}

@MainActor
final class GrowthViewModel: ObservableObject {
    @Published var badges: [Badge] = []

    // MARK: - Tiers — Path of Wisdom (6 levels)
    let tiers: [GrowthTier] = [
        GrowthTier(
            name: "Waking",
            minGP: 0,    maxGP: 200,
            description: "Something is waking up in you. You feel a pull toward growth but haven't yet named it.",
            color: Color(hex: "7B9CB8"),
            imageName: "OwlWaking"
        ),
        GrowthTier(
            name: "Seeking",
            minGP: 200,  maxGP: 450,
            description: "You're asking the real questions. You're willing to look honestly at yourself.",
            color: Color(hex: "C4873A"),
            imageName: "OwlSeeking"
        ),
        GrowthTier(
            name: "Emerging",
            minGP: 450,  maxGP: 700,
            description: "Layers are falling away. You're discovering who you are beneath the noise.",
            color: Color(hex: "4E7040"),
            imageName: "OwlEmerging"
        ),
        GrowthTier(
            name: "Aligned",
            minGP: 700,  maxGP: 2500,
            description: "Your actions reflect your values. You live with intention, not reaction.",
            color: Color(hex: "2D9B8A"),
            imageName: "OwlAligned"
        ),
        GrowthTier(
            name: "Flourishing",
            minGP: 2500, maxGP: 5000,
            description: "You're in full expression. Growth feels natural, not forced.",
            color: Color(hex: "C4A020"),
            imageName: "OwlFlourishing"
        ),
        GrowthTier(
            name: "Sage",
            minGP: 5000, maxGP: Int.max,
            description: "You carry wisdom lightly. Your presence itself is the gift.",
            color: Color(hex: "7B5EA7"),
            imageName: "OwlSage"
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

    // MARK: - Badges
    func loadBadges(totalGP: Int) {
        badges = [
            Badge(id: "pioneer",     title: "Pioneer",     emoji: "🏔️", description: "Earn your first GP",         requiredGP: 1,    isUnlocked: totalGP >= 1),
            Badge(id: "consistent",  title: "Consistent",  emoji: "🔥", description: "Reach 100 GP",               requiredGP: 100,  isUnlocked: totalGP >= 100),
            Badge(id: "seeking",     title: "Seeking",     emoji: "🔍", description: "Reach Seeking level",        requiredGP: 200,  isUnlocked: totalGP >= 200),
            Badge(id: "aware",       title: "Self-Aware",  emoji: "🌊", description: "Reach 350 GP",               requiredGP: 350,  isUnlocked: totalGP >= 350),
            Badge(id: "emerging",    title: "Emerging",    emoji: "🌿", description: "Reach Emerging level",       requiredGP: 450,  isUnlocked: totalGP >= 450),
            Badge(id: "aligned",     title: "Aligned",     emoji: "🎯", description: "Reach Aligned level",        requiredGP: 700,  isUnlocked: totalGP >= 700),
            Badge(id: "flourishing", title: "Flourishing", emoji: "🌸", description: "Reach Flourishing level",    requiredGP: 2500, isUnlocked: totalGP >= 2500),
            Badge(id: "sage",        title: "Sage",        emoji: "🦉", description: "Reach Sage level",           requiredGP: 5000, isUnlocked: totalGP >= 5000),
        ]
    }
}
