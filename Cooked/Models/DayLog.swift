import Foundation
import SwiftData

// MARK: - Supporting structs (Codable so SwiftData can store as JSON)

struct WorkoutLog: Codable, Identifiable {
    var id: UUID = UUID()
    var type: String          // "weightlifting", "run", "basketball", etc.
    var duration: TimeInterval // seconds
    var startTime: Date
}

struct FreePeriod: Codable, Identifiable {
    var id: UUID = UUID()
    var quality: PeriodQuality
}

// MARK: - DayLog

@Model
final class DayLog {

    // MARK: - Identity
    /// Normalised to midnight (start of calendar day)
    var date: Date = Date()

    // MARK: - School
    var schoolAttended: Bool = false

    /// Stored as JSON-encoded [FreePeriod]
    @Attribute(.externalStorage)
    var freePeriods: [FreePeriod] = []

    // MARK: - Homework
    /// Seconds between arriving home and starting homework; nil = not yet logged
    var homeworkDelay: TimeInterval? = nil
    var homeworkCompleted: Bool = false

    // MARK: - Physical
    /// Manual workout logs (supplements / replaces HealthKit when no Watch)
    @Attribute(.externalStorage)
    var workouts: [WorkoutLog] = []

    // MARK: - Sleep / night behaviour
    var doomscrolledInBed: Bool = false

    // MARK: - Extra credit
    var extraActivities: [String] = []

    // MARK: - Nap (optional)
    var napDuration: TimeInterval? = nil

    // MARK: - Meta
    var lastModified: Date = Date()

    init(date: Date = Calendar.current.startOfDay(for: Date())) {
        self.date = date
    }

    // MARK: - Helpers

    var productiveFreePeriods: Int {
        freePeriods.filter { $0.quality == .productive }.count
    }

    var wastedFreePeriods: Int {
        freePeriods.filter { $0.quality == .wasted }.count
    }

    var totalWorkoutDuration: TimeInterval {
        workouts.reduce(0) { $0 + $1.duration }
    }
}
