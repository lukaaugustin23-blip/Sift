import Foundation

// MARK: - RateLimitService
// Hard cap: 1 Claude API call per user per calendar day.
// Local guard via UserDefaults — server-side Supabase check is the second line of defence.

final class RateLimitService {

    static let shared = RateLimitService()
    private init() {}

    private let lastCallKey = "cooked_last_claude_call_date"
    private let defaults    = UserDefaults.standard

    // MARK: - Public API

    /// Returns true if Claude can be called today.
    func canCallClaudeToday() -> Bool {
        guard let stored = defaults.object(forKey: lastCallKey) as? Date else {
            return true  // never called
        }
        return !Calendar.current.isDateInToday(stored)
    }

    /// Call immediately after a successful Claude API response.
    func markClaudeCalled() {
        defaults.set(Date(), forKey: lastCallKey)
    }

    /// Human-readable string for UI — e.g. "Check back tonight"
    var nextAvailableLabel: String {
        guard let stored = defaults.object(forKey: lastCallKey) as? Date else {
            return "Available now"
        }
        if !Calendar.current.isDateInToday(stored) { return "Available now" }

        // Time until midnight
        let cal       = Calendar.current
        let tomorrow  = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: Date())!)
        let remaining = tomorrow.timeIntervalSince(Date())
        let hours     = Int(remaining / 3600)
        let minutes   = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 { return "Check back in \(hours)h \(minutes)m" }
        return "Check back in \(minutes)m"
    }

    /// True if user has already received their roast today.
    var hasCalledToday: Bool { !canCallClaudeToday() }

    // MARK: - Debug / testing

    #if DEBUG
    /// Reset for testing — never call in production code.
    func resetForTesting() {
        defaults.removeObject(forKey: lastCallKey)
    }
    #endif
}
