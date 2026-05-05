import Foundation
import SwiftData

@Model
final class UserProfile {

    // MARK: - Identity
    var name: String = ""

    /// Max 3 goals — enforced at write site
    var goals: [String] = []

    // MARK: - Roast preferences
    var roastStyle: RoastStyle = RoastStyle.savage
    var uncensoredMode: Bool = false

    // MARK: - School schedule
    /// Seconds from midnight — e.g. 8h = 28800
    var schoolStartTime: TimeInterval = 8 * 3600
    var schoolEndTime: TimeInterval   = 15 * 3600
    /// 1 = Mon … 7 = Sun (Calendar weekday values)
    var schoolDays: [Int] = [2, 3, 4, 5, 6]

    // MARK: - App categorisation (bundle IDs)
    var productiveAppBundleIds: [String] = []
    var wastedAppBundleIds: [String]     = []

    // MARK: - Workout preferences
    var typicalWorkouts: [String] = []

    // MARK: - Onboarding gate
    var onboardingCompleted: Bool = false

    // MARK: - Timestamps
    var createdAt: Date = Date()

    init(name: String = "") {
        self.name = name
    }

    // MARK: - Helpers

    /// True if today is a school day per user's schedule
    var isTodaySchoolDay: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return schoolDays.contains(weekday)
    }

    /// Clamped goal setter — never stores more than 3
    func addGoal(_ goal: String) {
        let trimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, goals.count < 3 else { return }
        goals.append(trimmed)
    }
}
