import Foundation

// MARK: - ClaudeService

final class ClaudeService {

    static let shared = ClaudeService()
    private init() {}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model    = "claude-sonnet-4-20250514"
    private let maxTokens = 200

    // MARK: - Public API

    /// Generates a roast for the given day. Throws on network/parse error.
    /// Rate limiting is enforced by RateLimitService before calling this.
    func generateRoast(
        score: DayScore,
        log: DayLog,
        profile: UserProfile
    ) async throws -> RoastResult {
        let prompt = buildPrompt(score: score, log: log, profile: profile)
        let payload = buildPayload(prompt: prompt)
        let data    = try await post(payload: payload)
        let text    = try extractText(from: data)
        return try RoastResult.decode(from: text)
    }

    // MARK: - Prompt builder (target < 100 tokens)

    private func buildPrompt(score: DayScore, log: DayLog, profile: UserProfile) -> String {
        let sleep   = formatSleep(score: score)
        let workout = formatWorkout(log: log, score: score)
        let school  = formatSchool(log: log, score: score)
        let hw      = formatHomework(log: log, score: score)
        let goals   = profile.goals.joined(separator: ", ")
        let style   = profile.roastStyle.promptInstruction
        let censor  = profile.uncensoredMode ? "Uncensored: swearing allowed." : "Keep it clean."

        return """
        Sleep: \(sleep)
        Workout: \(workout)
        Screen productive: \(formatTime(score.screenScore)), wasted: \(formatTime(100 - score.screenScore)), top app: \(log.extraActivities.first ?? "unknown")
        School: \(school)
        Homework: \(hw)
        Goals: \(goals.isEmpty ? "none" : goals)
        Roast style: \(style)
        \(censor)

        2-3 sentence roast based on this data. Be specific and brutal. Add one short tip for tomorrow.
        Return JSON only: {"roast":"...","tip":"..."}
        """
    }

    // MARK: - Prompt fragment helpers

    private func formatSleep(score: DayScore) -> String {
        "\(score.sleepScore)/100"
    }

    private func formatWorkout(log: DayLog, score: DayScore) -> String {
        if log.workouts.isEmpty {
            return "none logged, \(score.physicalScore)/100"
        }
        let types = log.workouts.map { $0.type }.joined(separator: "+")
        let mins  = Int(log.totalWorkoutDuration / 60)
        return "\(types) \(mins)min"
    }

    private func formatScreen(score: DayScore) -> String {
        "\(score.screenScore)/100"
    }

    private func formatSchool(log: DayLog, score: DayScore) -> String {
        log.schoolAttended
            ? "attended, \(log.productiveFreePeriods)P/\(log.wastedFreePeriods)W free periods"
            : "skipped"
    }

    private func formatHomework(log: DayLog, score: DayScore) -> String {
        guard log.homeworkCompleted else { return "not done" }
        if let delay = log.homeworkDelay, delay > 1800 {
            return "done, procrastinated \(Int(delay / 60))min"
        }
        return "done promptly"
    }

    private func formatTime(_ score: Int) -> String { "\(score)%" }

    // MARK: - Anthropic API payload

    private func buildPayload(prompt: String) -> [String: Any] {
        [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
    }

    // MARK: - Network

    private func post(payload: [String: Any]) async throws -> Data {
        var request = URLRequest(url: endpoint)
        request.httpMethod  = "POST"
        request.httpBody    = try JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json",     forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.claudeAPIKey,   forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",           forHTTPHeaderField: "anthropic-version")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "(empty)"
            throw ClaudeError.httpError(http.statusCode, body)
        }
        return data
    }

    // MARK: - Parse Anthropic envelope → text string

    private func extractText(from data: Data) throws -> String {
        let envelope = try JSONDecoder().decode(AnthropicMessagesResponse.self, from: data)
        guard let text = envelope.firstText else {
            throw ClaudeError.noTextContent
        }
        return text
    }
}

// MARK: - Errors

enum ClaudeError: LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case noTextContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:          return "Invalid response from Claude API."
        case .httpError(let c, let b):  return "Claude API error \(c): \(b)"
        case .noTextContent:            return "Claude returned no text content."
        }
    }
}
