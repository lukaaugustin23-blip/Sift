import Foundation
import SwiftData

// MARK: - Callout

struct Callout: Codable, Identifiable {
    var id: UUID = UUID()
    var type: CalloutType
    var emoji: String
    var text: String          // e.g. "Doomscrolled until 1am"

    var fullText: String { "\(emoji) \(text)" }
}

// MARK: - DayScore

@Model
final class DayScore {

    // MARK: - Identity
    /// Normalised to midnight — matches DayLog.date
    var date: Date = Date()

    // MARK: - Scores (0–100)
    var overall:       Int = 0
    var sleepScore:    Int = 0
    var physicalScore: Int = 0
    var screenScore:   Int = 0
    var schoolScore:   Int = 0
    var homeworkScore: Int = 0

    // MARK: - Grade (computed from overall)
    var grade: String = "F"   // stored as raw String; use Grade(rawValue: grade)

    // MARK: - AI output
    var roast: String = ""
    var tip:   String = ""

    // MARK: - Callouts
    @Attribute(.externalStorage)
    var callouts: [Callout] = []

    // MARK: - Meta
    var generatedAt: Date = Date()

    init(date: Date = Calendar.current.startOfDay(for: Date())) {
        self.date = date
    }

    // MARK: - Convenience

    var gradeValue: Grade { Grade.from(overall) }

    var isPassingDay: Bool { overall >= 50 }

    /// Scores mapped to category names — for sub-score bar rendering
    var categoryScores: [(name: String, score: Int)] {
        [
            ("Sleep",    sleepScore),
            ("Physical", physicalScore),
            ("Screen",   screenScore),
            ("School",   schoolScore),
            ("Homework", homeworkScore),
        ]
    }

    /// Call after computing all sub-scores to sync overall + grade
    func finalise() {
        overall = Int(
            Double(sleepScore)    * 0.25 +
            Double(physicalScore) * 0.20 +
            Double(screenScore)   * 0.20 +
            Double(schoolScore)   * 0.20 +
            Double(homeworkScore) * 0.15
        )
        grade = Grade.from(overall).rawValue
    }
}
