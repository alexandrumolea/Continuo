import Foundation
import HealthKit

/// Thin wrapper around HealthKit for mindful session read/write.
/// All methods are no-ops if HealthKit isn't available or the user hasn't authorized.
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var mindfulType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .mindfulSession)
    }

    /// Whether we're authorized to *write* mindful sessions.
    /// Apple intentionally hides read authorization status, so we infer "connected"
    /// from share auth (or, more reliably, from whether reads return data).
    var isWriteAuthorized: Bool {
        guard let type = mindfulType else { return false }
        return store.authorizationStatus(for: type) == .sharingAuthorized
    }

    /// Asks the user to share mindful sessions both ways. Returns true if write auth ended up granted.
    @discardableResult
    func requestMindfulnessAuth() async -> Bool {
        guard isAvailable, let type = mindfulType else { return false }
        let types: Set<HKSampleType> = [type]
        do {
            try await store.requestAuthorization(toShare: types, read: types)
            return isWriteAuthorized
        } catch {
            print("❌ HealthKit auth: \(error)")
            return false
        }
    }

    // MARK: - Read

    /// Total mindful minutes today, summed from HealthKit category samples.
    /// Returns 0 if not authorized for reading or no data.
    func mindfulnessMinutesToday() async -> Int {
        guard let type = mindfulType else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalSeconds = (samples as? [HKCategorySample] ?? [])
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: Int(totalSeconds / 60))
            }
            store.execute(query)
        }
    }

    /// All mindful sessions logged today, newest first.
    func mindfulnessSessionsToday() async -> [MindfulSession] {
        guard let type = mindfulType else { return [] }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                let sessions: [MindfulSession] = (samples as? [HKCategorySample] ?? []).map { sample in
                    let minutes = max(1, Int(sample.endDate.timeIntervalSince(sample.startDate) / 60))
                    return MindfulSession(id: sample.uuid,
                                          start: sample.startDate,
                                          end: sample.endDate,
                                          minutes: minutes,
                                          sourceName: sample.sourceRevision.source.name)
                }
                continuation.resume(returning: sessions)
            }
            store.execute(query)
        }
    }

    // MARK: - Write

    /// Writes a mindful session ending now of the given duration. Requires write authorization.
    @discardableResult
    func saveMindfulnessSession(durationMinutes: Int, endingAt end: Date = Date()) async -> Bool {
        guard durationMinutes > 0 else { return false }
        let start = end.addingTimeInterval(-Double(durationMinutes * 60))
        return await saveMindfulnessSession(start: start, end: end)
    }

    /// Writes a mindful session with explicit start/end dates. Requires write authorization.
    @discardableResult
    func saveMindfulnessSession(start: Date, end: Date) async -> Bool {
        guard let type = mindfulType, isWriteAuthorized, end > start else { return false }
        let sample = HKCategorySample(type: type,
                                      value: HKCategoryValue.notApplicable.rawValue,
                                      start: start, end: end)
        do {
            try await store.save(sample)
            return true
        } catch {
            print("❌ HealthKit save: \(error)")
            return false
        }
    }
}

// MARK: - Session value object

struct MindfulSession: Identifiable {
    let id: UUID
    let start: Date
    let end: Date
    let minutes: Int
    let sourceName: String
}
