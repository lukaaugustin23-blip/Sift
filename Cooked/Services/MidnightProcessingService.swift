import Foundation
import SwiftData

// MARK: - MidnightProcessingService
// Orchestrates end-of-day processing:
// HealthKit → ScreenTime → DayLog → Score → AI roast → persist.
// Call processDay() when user opens app after midnight.

@MainActor
final class MidnightProcessingService {

    static let shared = MidnightProcessingService()
    private init() {}

    // MARK: - Process

    /// Full pipeline for `date` (defaults to today).
    /// Returns the persisted DayScore on success.
    func processDay(
        for date: Date = .now,
        context: ModelContext,
        profile: UserProfile
    ) async throws -> DayScore {

        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        // ── 1. Check rate limit ──────────────────────────────────────────────
        guard RateLimitService.shared.canCallClaudeToday() else {
            // Return existing score if already processed today
            if let existing = existingScore(for: targetDay, context: context) {
                return existing
            }
            throw ProcessingError.rateLimitExceeded
        }

        // ── 2. Fetch HealthKit ───────────────────────────────────────────────
        let health = await HealthKitService.shared.fetchAllHealthData(for: date)

        // ── 3. Fetch Screen Time ─────────────────────────────────────────────
        let screen = await ScreenTimeService.shared.fetchScreenTime(for: date, profile: profile)

        // ── 4. Load today's DayLog (create if absent) ────────────────────────
        let log = fetchOrCreateLog(for: targetDay, context: context)

        // ── 5. Score ─────────────────────────────────────────────────────────
        let score = ScoringService.shared.calculateScore(
            health: health,
            screen: screen,
            log: log,
            profile: profile
        )
        score.date = targetDay

        // ── 6. AI roast ──────────────────────────────────────────────────────
        do {
            let result = try await ClaudeService.shared.generateRoast(
                score: score,
                log: log,
                profile: profile
            )
            score.roast = result.roast
            score.tip   = result.tip
        } catch {
            // Non-fatal: keep empty roast, show generic fallback
            score.roast = fallbackRoast(score: score, style: profile.roastStyle)
            score.tip   = "Track your day fully tomorrow for a personalised tip."
        }

        // Mark rate limit consumed
        RateLimitService.shared.markClaudeCalled()

        // ── 7. Persist ───────────────────────────────────────────────────────
        // Remove any prior score for same day
        if let old = existingScore(for: targetDay, context: context) {
            context.delete(old)
        }

        context.insert(score)
        try context.save()

        return score
    }

    // MARK: - Helpers

    private func fetchOrCreateLog(for day: Date, context: ModelContext) -> DayLog {
        let descriptor = FetchDescriptor<DayLog>(
            predicate: #Predicate { $0.date >= day }
        )
        let all = (try? context.fetch(descriptor)) ?? []
        let calendar = Calendar.current
        if let existing = all.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            return existing
        }
        let log = DayLog(date: day)
        context.insert(log)
        return log
    }

    private func existingScore(for day: Date, context: ModelContext) -> DayScore? {
        let descriptor = FetchDescriptor<DayScore>(
            predicate: #Predicate { $0.date >= day }
        )
        let all = (try? context.fetch(descriptor)) ?? []
        let calendar = Calendar.current
        return all.first(where: { calendar.isDate($0.date, inSameDayAs: day) })
    }

    // MARK: - Fallback roast (when AI call fails)

    private func fallbackRoast(score: DayScore, style: RoastStyle) -> String {
        let overall = score.overall
        switch style {
        case .savage:
            return overall >= 70
                ? "Decent. Don't get comfortable."
                : "You had a full day and still managed to waste it. Impressive in the worst way."
        case .disappointedParent:
            return overall >= 70
                ? "Not bad. I expected worse, honestly."
                : "I'm not angry. I'm just disappointed. Again."
        case .coach:
            return overall >= 70
                ? "Solid effort today. Keep stacking wins."
                : "Off day. Reset, recover, come back stronger."
        case .sarcastic:
            return overall >= 70
                ? "Oh wow, you actually tried today. Who are you?"
                : "Revolutionary concept: doing things. Try it sometime."
        }
    }
}

// MARK: - Errors

enum ProcessingError: LocalizedError {
    case rateLimitExceeded
    case noProfile

    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded: return "Already processed today. Check back after midnight."
        case .noProfile:         return "No user profile found."
        }
    }
}
