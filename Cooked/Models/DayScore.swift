import Foundation
import SwiftData

@Model
final class DayScore {
    var date: Date
    var overall: Int                // 0–100 productive score
    var productiveTime: TimeInterval
    var wastedTime: TimeInterval
    var topWastedApp: String
    var roast: String
    var tip: String
    @Attribute(.externalStorage) var callouts: [Callout]
    var generatedAt: Date

    init(
        date: Date = Calendar.current.startOfDay(for: Date()),
        overall: Int = 0,
        productiveTime: TimeInterval = 0,
        wastedTime: TimeInterval = 0,
        topWastedApp: String = "",
        roast: String = "",
        tip: String = "",
        callouts: [Callout] = [],
        generatedAt: Date = Date()
    ) {
        self.date = date
        self.overall = overall
        self.productiveTime = productiveTime
        self.wastedTime = wastedTime
        self.topWastedApp = topWastedApp
        self.roast = roast
        self.tip = tip
        self.callouts = callouts
        self.generatedAt = generatedAt
    }

    // MARK: - Computed

    var grade: String   { Grade.from(overall).rawValue }
    var gradeValue: Grade { Grade.from(overall) }

    var totalScreenTime: TimeInterval { productiveTime + wastedTime }

    var productiveRatio: Double {
        guard totalScreenTime > 0 else { return 0 }
        return productiveTime / totalScreenTime
    }

    // Formatted time strings
    var productiveFormatted: String { formatTime(productiveTime) }
    var wastedFormatted:     String { formatTime(wastedTime) }

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t / 3600)
        let m = Int((t.truncatingRemainder(dividingBy: 3600)) / 60)
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
