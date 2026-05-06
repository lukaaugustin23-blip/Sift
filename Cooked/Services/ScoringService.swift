import Foundation

// MARK: - ScoringService
// Converts ScreenTimeData → DayScore. No HealthKit. No manual logs.

final class ScoringService {
    static let shared = ScoringService()
    private init() {}

    func calculateScore(screen: ScreenTimeData, profile: UserProfile) -> DayScore {
        let score = DayScore()
        score.date            = Calendar.current.startOfDay(for: Date())
        score.productiveTime  = screen.productiveTime
        score.wastedTime      = screen.wastedTime
        score.topWastedApp    = screen.topApp
        score.generatedAt     = Date()

        // Base: productive ratio 0–100
        var overall: Int
        if screen.totalTime < 60 {
            overall = 50 // Not enough data — neutral
        } else {
            overall = Int(screen.productiveRatio * 100)
        }

        // Penalty: excessive total screen time
        let totalHours = screen.totalTime / 3600
        if totalHours > 8  { overall = max(0, overall - 15) }
        if totalHours > 10 { overall = max(0, overall - 15) }

        // Penalty: excessive wasted time
        let wastedHours = screen.wastedTime / 3600
        if wastedHours > 2 { overall = max(0, overall - 10) }
        if wastedHours > 3 { overall = max(0, overall - 10) }

        score.overall  = max(0, min(100, overall))
        score.callouts = generateCallouts(screen: screen, score: score.overall)
        return score
    }

    // MARK: - Callouts

    private func generateCallouts(screen: ScreenTimeData, score: Int) -> [Callout] {
        var out: [Callout] = []
        let wastedH  = screen.wastedTime / 3600
        let prodH    = screen.productiveTime / 3600
        let totalH   = screen.totalTime / 3600

        if prodH >= 2 {
            out.append(Callout(type: .positive, emoji: "✅", text: "\(Int(prodH))h productive"))
        }
        if wastedH >= 1 {
            out.append(Callout(type: .negative, emoji: "⏱️", text: "\(Int(wastedH))h wasted"))
        }
        if !screen.topApp.isEmpty && screen.topApp != "Unknown" {
            out.append(Callout(type: .negative, emoji: "📱", text: screen.topApp))
        }
        if totalH > 8 {
            out.append(Callout(type: .negative, emoji: "💀", text: "\(Int(totalH))h on phone"))
        }
        if score >= 80 {
            out.append(Callout(type: .positive, emoji: "🔥", text: "Great day"))
        }
        return Array(out.prefix(4))
    }
}
