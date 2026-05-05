import Foundation
import HealthKit

// MARK: - ScoringService

final class ScoringService {

    static let shared = ScoringService()
    private init() {}

    // MARK: - Main entry point

    func calculateScore(
        health: HealthData,
        screen: ScreenTimeData,
        log: DayLog,
        profile: UserProfile
    ) -> DayScore {
        let score = DayScore(date: log.date)

        score.sleepScore    = computeSleepScore(health: health, log: log)
        score.physicalScore = computePhysicalScore(health: health, log: log)
        score.screenScore   = computeScreenScore(screen: screen)
        score.schoolScore   = computeSchoolScore(log: log, profile: profile)
        score.homeworkScore = computeHomeworkScore(log: log)

        score.callouts      = generateCallouts(health: health, screen: screen, log: log)
        score.finalise()

        return score
    }

    // MARK: - Sleep (25%)
    // Full: 7–9 hrs, bedtime before midnight
    // Penalty: -20 doomscroll in bed, -15 bedtime past 1am, ramp down outside range

    private func computeSleepScore(health: HealthData, log: DayLog) -> Int {
        let hours = health.sleep.totalDuration / 3600
        var score: Double

        switch hours {
        case 7..<9:       score = 100
        case 6..<7:       score = 80
        case 9..<10:      score = 85
        case 5..<6:       score = 55
        case 10...:       score = 70
        default:          score = 20   // < 5h or no data
        }

        // Bedtime penalty
        if let bedtime = health.sleep.bedtime {
            let hour = Calendar.current.component(.hour, from: bedtime)
            if hour >= 1 && hour < 12 {          // past 1am (hour 1..11 = 1am–11am)
                score -= 15
            } else if hour == 0 {                 // midnight–1am: small nudge
                score -= 5
            }
        }

        // Doomscroll penalty
        if log.doomscrolledInBed { score -= 20 }

        return max(0, min(100, Int(score)))
    }

    // MARK: - Physical (20%)
    // Full: 45+ min workout logged
    // Partial: steps > 8k, active energy > 400 kcal
    // HKWorkout from HealthKit stacks with manual logs

    private func computePhysicalScore(health: HealthData, log: DayLog) -> Int {
        // Combine HealthKit workout minutes + manual logs
        let hkMinutes  = health.workouts.reduce(0.0) { $0 + $1.duration / 60 }
        let manMinutes = log.totalWorkoutDuration / 60
        let totalMinutes = hkMinutes + manMinutes

        var score: Double = 0

        switch totalMinutes {
        case 60...:   score = 100
        case 45..<60: score = 90
        case 30..<45: score = 70
        case 15..<30: score = 45
        case 1..<15:  score = 20
        default:      score = 0
        }

        // Bonus for step count even without workout
        if score < 50 {
            if health.steps >= 10_000 { score = max(score, 60) }
            else if health.steps >= 8_000 { score = max(score, 45) }
            else if health.steps >= 5_000 { score = max(score, 30) }
        }

        // Bonus for active energy
        if health.activeEnergy >= 500 { score = min(100, score + 10) }
        else if health.activeEnergy >= 400 { score = min(100, score + 5) }

        return max(0, min(100, Int(score)))
    }

    // MARK: - Screen Time (20%)
    // Ratio productive:wasted; penalty for excessive total or binge on wasted apps

    private func computeScreenScore(screen: ScreenTimeData) -> Int {
        // No data → neutral 50
        guard screen.totalTime > 0 else { return 50 }

        let totalHours = screen.totalTime / 3600
        let ratio      = screen.productiveRatio  // 0..1

        // Base from productive ratio
        var score = ratio * 100

        // Total time penalty (> 8h is excessive regardless of split)
        if totalHours > 10 { score -= 30 }
        else if totalHours > 8 { score -= 15 }
        else if totalHours > 6 { score -= 5 }

        // Wasted binge penalty (> 2h straight wasted)
        let wastedHours = screen.wastedTime / 3600
        if wastedHours > 3  { score -= 20 }
        else if wastedHours > 2 { score -= 10 }

        return max(0, min(100, Int(score)))
    }

    // MARK: - School / Work (20%)
    // Base: attended; bonus per productive free period; penalty per wasted

    private func computeSchoolScore(log: DayLog, profile: UserProfile) -> Int {
        // If today wasn't a scheduled school day, score is neutral
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: log.date)
        guard profile.schoolDays.contains(weekday) else { return 75 }

        guard log.schoolAttended else { return 0 }

        var score = 70  // base for attending
        score += log.productiveFreePeriods * 10
        score -= log.wastedFreePeriods * 8

        return max(0, min(100, score))
    }

    // MARK: - Homework / Deep Work (15%)
    // Full: done within 30min. Partial: done late. Zero: not done.

    private func computeHomeworkScore(log: DayLog) -> Int {
        guard log.homeworkCompleted else { return 0 }

        let delayMinutes = (log.homeworkDelay ?? 0) / 60

        switch delayMinutes {
        case 0..<30:   return 100
        case 30..<60:  return 80
        case 60..<90:  return 65
        case 90..<120: return 45
        case 120...:   return 25
        default:       return 100
        }
    }

    // MARK: - Callout generation

    private func generateCallouts(
        health: HealthData,
        screen: ScreenTimeData,
        log: DayLog
    ) -> [Callout] {
        var callouts: [Callout] = []

        // Sleep callouts
        if log.doomscrolledInBed {
            callouts.append(Callout(type: .negative, emoji: "💀", text: "Doomscrolled in bed"))
        }
        if let bedtime = health.sleep.bedtime {
            let hour = Calendar.current.component(.hour, from: bedtime)
            if hour >= 1 && hour < 12 {
                let fmt = DateFormatter(); fmt.dateFormat = "h:mma"
                callouts.append(Callout(type: .negative, emoji: "🌙", text: "Bedtime: \(fmt.string(from: bedtime).lowercased())"))
            }
        }
        let sleepHours = health.sleep.totalDuration / 3600
        if sleepHours >= 7 && sleepHours <= 9 {
            callouts.append(Callout(type: .positive, emoji: "😴", text: String(format: "%.1fh sleep", sleepHours)))
        }

        // Workout callouts
        let allWorkouts = log.workouts
        for w in allWorkouts {
            let fmt = DateFormatter(); fmt.dateFormat = "ha"
            let mins = Int(w.duration / 60)
            callouts.append(Callout(
                type: .positive, emoji: "🔥",
                text: "\(w.type.capitalized) \(mins)min at \(fmt.string(from: w.startTime).lowercased())"
            ))
        }
        if allWorkouts.isEmpty && health.workouts.isEmpty {
            if health.steps < 3_000 {
                callouts.append(Callout(type: .negative, emoji: "🪑", text: "Barely moved today"))
            }
        }
        if health.steps >= 10_000 {
            callouts.append(Callout(type: .positive, emoji: "👟", text: "\(health.steps.formatted()) steps"))
        }

        // Screen callouts
        if screen.totalTime / 3600 > 8 {
            callouts.append(Callout(type: .negative, emoji: "📱", text: String(format: "%.1fh screen time", screen.totalTime / 3600)))
        }
        if !screen.topApp.isEmpty && screen.topApp != "Unknown" {
            let topHours = screen.wastedTime / 3600
            if topHours > 2 {
                callouts.append(Callout(type: .negative, emoji: "📵", text: String(format: "%.1fh wasted screen time", topHours)))
            }
        }

        // Homework callouts
        if !log.homeworkCompleted {
            callouts.append(Callout(type: .negative, emoji: "❌", text: "Homework not done"))
        } else if let delay = log.homeworkDelay, delay > 7200 {
            callouts.append(Callout(type: .negative, emoji: "⏰", text: "Homework: procrastinated \(Int(delay / 3600))h"))
        } else if log.homeworkCompleted {
            callouts.append(Callout(type: .positive, emoji: "✅", text: "Homework done"))
        }

        // Extra activities
        for activity in log.extraActivities {
            callouts.append(Callout(type: .positive, emoji: "⭐️", text: activity.capitalized))
        }

        return callouts
    }
}
