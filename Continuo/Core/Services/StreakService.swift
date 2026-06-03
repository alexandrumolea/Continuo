import Foundation
import FirebaseFirestore

final class StreakService {
    static let shared = StreakService()
    private let db = Firestore.firestore()

    // MARK: - Helpers

    private func dateKey(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Update streak after any activity
    // Safe to call multiple times per day — idempotent if lastActivityDate == today.

    func updateStreak(userId: String) async {
        let today     = dateKey()
        let yesterday = dateKey(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        let userRef   = db.collection("users").document(userId)

        do {
            let snap  = try await userRef.getDocument()
            let data  = snap.data() ?? [:]
            let last  = data["lastActivityDate"] as? String ?? ""
            let cur   = data["currentStreak"]    as? Int ?? 0
            let best  = data["longestStreak"]    as? Int ?? 0

            guard last != today else { return }  // already recorded today

            let newStreak: Int = last == yesterday ? cur + 1 : 1
            let newBest = max(best, newStreak)

            try await userRef.updateData([
                "lastActivityDate": today,
                "currentStreak":    newStreak,
                "longestStreak":    newBest
            ])
        } catch {
            print("❌ StreakService: \(error.localizedDescription)")
        }
    }

    // MARK: - Recent activity dates (for heatmap in Growth screen)
    // Returns a Set of "yyyy-MM-dd" keys for any day that had at least one dailyCompletion
    // in the last `days` days.

    func recentActivityDates(userId: String, days: Int = 30) async -> Set<String> {
        let cal   = Calendar.current
        let today = Date()
        guard let start = cal.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let startKey = f.string(from: start)

        guard let snap = try? await db.collection("users").document(userId)
            .collection("dailyCompletions").getDocuments() else { return [] }

        // Document IDs are "{practiceId}_{dateKey}" — extract unique dateKeys in range
        var keys = Set<String>()
        for doc in snap.documents {
            guard let dateKey = doc.documentID.split(separator: "_").last.map(String.init),
                  dateKey.count == 10, dateKey >= startKey else { continue }
            keys.insert(dateKey)
        }
        return keys
    }
}
