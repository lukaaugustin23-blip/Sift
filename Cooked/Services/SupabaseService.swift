import Foundation

// MARK: - Supabase stub (leaderboard — not yet built)

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    enum SupabaseError: Error { case notImplemented }

    func submitScore(_ score: DayScore, profile: UserProfile) async throws {
        throw SupabaseError.notImplemented
    }
}
