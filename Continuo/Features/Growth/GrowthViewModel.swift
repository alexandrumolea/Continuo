import Foundation
import Combine
import SwiftUI

struct GrowthTier: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let minGP: Int
    let maxGP: Int
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

    // MARK: - Tiers
    let tiers: [GrowthTier] = [
        GrowthTier(name: "Seedling",  emoji: "🌱",  minGP: 0,    maxGP: 100),
        GrowthTier(name: "Sprout",    emoji: "🌿",  minGP: 100,  maxGP: 300),
        GrowthTier(name: "Bloom",     emoji: "🌸",  minGP: 300,  maxGP: 600),
        GrowthTier(name: "Flourish",  emoji: "🌳",  minGP: 600,  maxGP: 1000),
        GrowthTier(name: "Radiant",   emoji: "✨",  minGP: 1000, maxGP: Int.max),
    ]

    func currentTier(gp: Int) -> GrowthTier {
        tiers.last(where: { gp >= $0.minGP }) ?? tiers[0]
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
            Badge(id: "pioneer",    title: "Pioneer",     emoji: "🏔️", description: "Earn your first GP",    requiredGP: 1,   isUnlocked: totalGP >= 1),
            Badge(id: "consistent", title: "Consistent",  emoji: "🔥", description: "Reach 50 GP",           requiredGP: 50,  isUnlocked: totalGP >= 50),
            Badge(id: "aligned",    title: "Deep Aligned",emoji: "🎯", description: "Reach 100 GP",          requiredGP: 100, isUnlocked: totalGP >= 100),
            Badge(id: "aware",      title: "Self-Aware",  emoji: "🌊", description: "Reach 150 GP",          requiredGP: 150, isUnlocked: totalGP >= 150),
            Badge(id: "ascending",  title: "Ascending",   emoji: "⬆️", description: "Reach 200 GP",          requiredGP: 200, isUnlocked: totalGP >= 200),
            Badge(id: "bloom",      title: "In Bloom",    emoji: "🌸", description: "Reach Bloom tier",      requiredGP: 300, isUnlocked: totalGP >= 300),
            Badge(id: "radiant",    title: "Radiant",     emoji: "✨", description: "Reach 500 GP",          requiredGP: 500, isUnlocked: totalGP >= 500),
            Badge(id: "master",     title: "Master",      emoji: "🏆", description: "Reach Radiant tier",    requiredGP: 1000,isUnlocked: totalGP >= 1000),
        ]
    }
}
