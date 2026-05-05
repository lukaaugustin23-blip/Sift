import Foundation

// MARK: - Supabase config (fill in when leaderboard is built)
// Add real URL + anon key to Secrets.swift when ready.

private enum SupabaseConfig {
    static let url    = "https://REPLACE_ME.supabase.co"
    static let anonKey = "REPLACE_ME"
}

// MARK: - Leaderboard entry

struct LeaderboardEntry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var username: String
    var score: Int
    var sleepScore: Int
    var physicalScore: Int
    var screenScore: Int
    var schoolScore: Int
    var homeworkScore: Int
    var streak: Int
    var week: String          // ISO week string e.g. "2026-W18"
    var createdAt: Date
}

// MARK: - SupabaseService (stub — filled in during leaderboard step)

final class SupabaseService {

    static let shared = SupabaseService()
    private init() {}

    // MARK: - Auth (stub)

    func signUp(email: String, password: String) async throws {
        // TODO: POST /auth/v1/signup
        throw SupabaseError.notImplemented
    }

    func signIn(email: String, password: String) async throws {
        // TODO: POST /auth/v1/token?grant_type=password
        throw SupabaseError.notImplemented
    }

    func signOut() async {
        // TODO: POST /auth/v1/logout
    }

    // MARK: - Leaderboard (stub)

    /// Submit today's DayScore to the global leaderboard.
    func submitScore(_ score: DayScore, username: String, streak: Int) async throws {
        // TODO: POST /rest/v1/scores
        // Rate limit enforced by Supabase RLS — only 1 row per user per week
        throw SupabaseError.notImplemented
    }

    /// Fetch weekly global leaderboard (top 100).
    func fetchLeaderboard(week: String? = nil) async throws -> [LeaderboardEntry] {
        // TODO: GET /rest/v1/scores?select=*&order=score.desc&limit=100
        throw SupabaseError.notImplemented
    }

    /// Fetch friends leaderboard by username list (Pro feature).
    func fetchFriendsLeaderboard(usernames: [String]) async throws -> [LeaderboardEntry] {
        // TODO: GET /rest/v1/scores?username=in.(...)
        throw SupabaseError.notImplemented
    }

    // MARK: - Server-side rate limit verification (stub)

    /// Secondary check — confirms user hasn't already called Claude today server-side.
    func verifyClaudeRateLimit(userId: UUID) async throws -> Bool {
        // TODO: query last_roast_at from users table
        return true  // optimistic until implemented
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notImplemented
    case networkError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notImplemented:        return "Supabase not yet configured."
        case .networkError(let msg): return "Network error: \(msg)"
        case .unauthorized:          return "Not signed in."
        }
    }
}
