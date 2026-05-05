import Foundation
import HealthKit

// MARK: - Data types

struct SleepData {
    var bedtime: Date?
    var wakeTime: Date?
    var totalDuration: TimeInterval   // seconds of actual sleep
}

struct HealthData {
    var sleep: SleepData
    var workouts: [HKWorkout]
    var steps: Int
    var activeEnergy: Double          // kcal
}

// MARK: - HealthKitService

final class HealthKitService {

    static let shared = HealthKitService()
    private let store = HKHealthStore()
    private init() {}

    // MARK: - Types to read

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        types.insert(HKObjectType.workoutType())
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            print("[HealthKit] Auth failed: \(error.localizedDescription)")
            return false
        }
    }

    var isAuthorized: Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let status = store.authorizationStatus(
            for: HKObjectType.quantityType(forIdentifier: .stepCount)!
        )
        return status == .sharingAuthorized
    }

    // MARK: - Sleep

    func fetchSleepData(for date: Date) async -> SleepData {
        let cal = Calendar.current
        // Query window: noon previous day → noon target day
        let start = cal.date(byAdding: .hour, value: -12, to: cal.startOfDay(for: date))!
        let end   = cal.date(byAdding: .hour, value: 12,  to: cal.startOfDay(for: date))!

        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: .strictStartDate
        )
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                guard error == nil, let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: SleepData(bedtime: nil, wakeTime: nil, totalDuration: 0))
                    return
                }
                // Only asleep stages (core, deep, REM)
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                ]
                let asleep = samples.filter { asleepValues.contains($0.value) }
                let total  = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let bedtime  = asleep.first?.startDate
                let wakeTime = asleep.last?.endDate
                continuation.resume(returning: SleepData(
                    bedtime: bedtime, wakeTime: wakeTime, totalDuration: total
                ))
            }
            store.execute(query)
        }
    }

    // MARK: - Workouts

    func fetchWorkouts(for date: Date) async -> [HKWorkout] {
        let (start, end) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: .strictStartDate
        )
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
    }

    // MARK: - Steps

    func fetchSteps(for date: Date) async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let (start, end) = dayBounds(for: date)
        return await fetchSum(type: type, unit: .count(), start: start, end: end).map { Int($0) } ?? 0
    }

    // MARK: - Active Energy

    func fetchActiveEnergy(for date: Date) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let (start, end) = dayBounds(for: date)
        return await fetchSum(type: type, unit: .kilocalorie(), start: start, end: end) ?? 0
    }

    // MARK: - Aggregate helper

    func fetchAllHealthData(for date: Date) async -> HealthData {
        async let sleep    = fetchSleepData(for: date)
        async let workouts = fetchWorkouts(for: date)
        async let steps    = fetchSteps(for: date)
        async let energy   = fetchActiveEnergy(for: date)
        return await HealthData(
            sleep: sleep, workouts: workouts, steps: steps, activeEnergy: energy
        )
    }

    // MARK: - Private helpers

    private func dayBounds(for date: Date) -> (Date, Date) {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: date)
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    private func fetchSum(
        type: HKQuantityType,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> Double? {
        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: .strictStartDate
        )
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
