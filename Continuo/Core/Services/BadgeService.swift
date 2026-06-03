import Foundation
import FirebaseFirestore

// MARK: - Badge category

enum BadgeCategory: String, CaseIterable {
    case coaching   = "coaching"
    case practice   = "practice"
    case competency = "competency"

    var title: String {
        switch self {
        case .coaching:   return "Coaching"
        case .practice:   return "Daily Practice"
        case .competency: return "Competency"
        }
    }
}

// MARK: - Badge definition (static catalog)

struct BadgeDefinition: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let description: String
    let category: BadgeCategory
    let threshold: Int   // sessions / practices / competency points
}

// MARK: - Badge service

final class BadgeService {
    static let shared = BadgeService()
    private let db = Firestore.firestore()

    // MARK: - Catalog (order = unlock order within each series)

    static let catalog: [BadgeDefinition] = [
        // ── Coaching ──────────────────────────────────────────
        BadgeDefinition(id: "coach_3",   title: "Guided",       emoji: "🤝",
                        description: "Have 3 coaching sessions",   category: .coaching, threshold: 3),
        BadgeDefinition(id: "coach_6",   title: "Committed",    emoji: "🧭",
                        description: "Have 6 coaching sessions",   category: .coaching, threshold: 6),
        BadgeDefinition(id: "coach_10",  title: "Invested",     emoji: "🔑",
                        description: "Have 10 coaching sessions",  category: .coaching, threshold: 10),
        BadgeDefinition(id: "coach_30",  title: "Forged",       emoji: "🏛️",
                        description: "Have 30 coaching sessions",  category: .coaching, threshold: 30),
        BadgeDefinition(id: "coach_50",  title: "Dedicated",    emoji: "🌍",
                        description: "Have 50 coaching sessions",  category: .coaching, threshold: 50),
        BadgeDefinition(id: "coach_100", title: "Transcendent", emoji: "🔱",
                        description: "Have 100 coaching sessions", category: .coaching, threshold: 100),

        // ── Daily Practice ────────────────────────────────────
        BadgeDefinition(id: "practice_1",   title: "First Step",  emoji: "🌱",
                        description: "Complete 1 daily practice",    category: .practice, threshold: 1),
        BadgeDefinition(id: "practice_3",   title: "Momentum",    emoji: "🔥",
                        description: "Complete 3 daily practices",   category: .practice, threshold: 3),
        BadgeDefinition(id: "practice_10",  title: "Devoted",     emoji: "💎",
                        description: "Complete 10 daily practices",  category: .practice, threshold: 10),
        BadgeDefinition(id: "practice_20",  title: "Flowing",     emoji: "🌊",
                        description: "Complete 20 daily practices",  category: .practice, threshold: 20),
        BadgeDefinition(id: "practice_35",  title: "Ascending",   emoji: "🏔️",
                        description: "Complete 35 daily practices",  category: .practice, threshold: 35),
        BadgeDefinition(id: "practice_50",  title: "Relentless",  emoji: "⚡",
                        description: "Complete 50 daily practices",  category: .practice, threshold: 50),
        BadgeDefinition(id: "practice_100", title: "Legend",      emoji: "👑",
                        description: "Complete 100 daily practices", category: .practice, threshold: 100),

        // ── Competency (highest single competency score) ──────
        BadgeDefinition(id: "comp_10",  title: "Spark",     emoji: "✨",
                        description: "Reach 10 pts in any competency",  category: .competency, threshold: 10),
        BadgeDefinition(id: "comp_20",  title: "Rooted",    emoji: "🌿",
                        description: "Reach 20 pts in any competency",  category: .competency, threshold: 20),
        BadgeDefinition(id: "comp_35",  title: "Deepening", emoji: "🔮",
                        description: "Reach 35 pts in any competency",  category: .competency, threshold: 35),
        BadgeDefinition(id: "comp_50",  title: "Radiant",   emoji: "🌟",
                        description: "Reach 50 pts in any competency",  category: .competency, threshold: 50),
        BadgeDefinition(id: "comp_100", title: "Sage Mind", emoji: "🦉",
                        description: "Reach 100 pts in any competency", category: .competency, threshold: 100),
    ]

    // MARK: - Real-time listener (badge IDs + earned dates)

    func earnedBadgesListener(
        userId: String,
        onChange: @escaping ([String: Date]) -> Void
    ) -> ListenerRegistration {
        db.collection("users").document(userId)
            .collection("earnedBadges")
            .addSnapshotListener { snap, _ in
                var result: [String: Date] = [:]
                snap?.documents.forEach { doc in
                    if let ts = doc.data()["earnedAt"] as? Timestamp {
                        result[doc.documentID] = ts.dateValue()
                    }
                }
                onChange(result)
            }
    }

    // MARK: - One-shot fetch of earned IDs (for badge checks in services)

    func fetchEarnedIds(userId: String) async -> Set<String> {
        let snap = try? await db.collection("users").document(userId)
            .collection("earnedBadges").getDocuments()
        return Set(snap?.documents.map(\.documentID) ?? [])
    }

    // MARK: - Award helpers (category-specific — called from the relevant service)

    func checkAndAwardPractice(userId: String, practiceCount: Int) async {
        let earnedIds = await fetchEarnedIds(userId: userId)
        await awardIfNeeded(userId: userId, earnedIds: earnedIds,
                            badges: Self.catalog.filter { $0.category == .practice },
                            value: practiceCount)
    }

    func checkAndAwardCoaching(userId: String, coachingCount: Int) async {
        let earnedIds = await fetchEarnedIds(userId: userId)
        await awardIfNeeded(userId: userId, earnedIds: earnedIds,
                            badges: Self.catalog.filter { $0.category == .coaching },
                            value: coachingCount)
    }

    func checkAndAwardCompetency(userId: String, maxScore: Int) async {
        let earnedIds = await fetchEarnedIds(userId: userId)
        await awardIfNeeded(userId: userId, earnedIds: earnedIds,
                            badges: Self.catalog.filter { $0.category == .competency },
                            value: maxScore)
    }

    // MARK: - Private

    private func awardIfNeeded(userId: String, earnedIds: Set<String>,
                               badges: [BadgeDefinition], value: Int) async {
        for badge in badges {
            guard !earnedIds.contains(badge.id), value >= badge.threshold else { continue }
            do {
                try await db.collection("users").document(userId)
                    .collection("earnedBadges")
                    .document(badge.id)
                    .setData(["earnedAt": Timestamp(date: Date())])
            } catch {
                print("❌ BadgeService award \(badge.id): \(error.localizedDescription)")
            }
        }
    }
}
