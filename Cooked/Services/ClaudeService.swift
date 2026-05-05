import Foundation

// MARK: - GroqService (named ClaudeService for internal compatibility)
// Uses Groq's OpenAI-compatible API for roast generation.
// Model: llama-3.3-70b-versatile — fast, cheap, great at creative writing.

final class ClaudeService {

    static let shared = ClaudeService()
    private init() {}

    private let endpoint  = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let model     = "llama-3.3-70b-versatile"
    private let maxTokens = 200

    // MARK: - Public API

    /// Generates a roast for the given day. Throws on network/parse error.
    /// Rate limiting enforced by RateLimitService before calling this.
    func generateRoast(
        score: DayScore,
        log: DayLog,
        profile: UserProfile
    ) async throws -> RoastResult {
        let prompt  = buildPrompt(score: score, log: log, profile: profile)
        let payload = buildPayload(prompt: prompt)
        let data    = try await post(payload: payload)
        let text    = try extractText(from: data)
        return try RoastResult.decode(from: text)
    }

    // MARK: - Prompt builder (target < 100 tokens input)

    private func buildPrompt(score: DayScore, log: DayLog, profile: UserProfile) -> String {
        let sleep   = formatSleep(score: score)
        let workout = formatWorkout(log: log)
        let school  = formatSchool(log: log)
        let hw      = formatHomework(log: log)
        let goals   = profile.goals.isEmpty ? "none" : profile.goals.joined(separator: ", ")
        let style   = profile.roastStyle.promptInstruction
        let censor  = profile.uncensoredMode ? "Uncensored: swearing allowed." : "Keep it clean."

        return """
        Sleep: \(sleep)
        Workout: \(workout)
        Screen productive: \(score.screenScore)%, wasted: \(100 - score.screenScore)%
        School: \(school)
        Homework: \(hw)
        Goals: \(goals)
        Roast style: \(style)
        \(censor)

        2-3 sentence roast based on this data. Be specific and brutal. Add one short tip for tomorrow.
        Return JSON only: {"roast":"...","tip":"..."}
        """
    }

    // MARK: - Prompt fragments

    private func formatSleep(score: DayScore) -> String { "\(score.sleepScore)/100" }

    private func formatWorkout(log: DayLog) -> String {
        guard !log.workouts.isEmpty else { return "none" }
        let types = log.workouts.map { $0.type }.joined(separator: "+")
        let mins  = Int(log.totalWorkoutDuration / 60)
        return "\(types) \(mins)min"
    }

    private func formatSchool(log: DayLog) -> String {
        log.schoolAttended
            ? "attended, \(log.productiveFreePeriods)P/\(log.wastedFreePeriods)W free periods"
            : "skipped"
    }

    private func formatHomework(log: DayLog) -> String {
        guard log.homeworkCompleted else { return "not done" }
        if let delay = log.homeworkDelay, delay > 1800 {
            return "done, procrastinated \(Int(delay / 60))min"
        }
        return "done promptly"
    }

    // MARK: - Groq request payload (OpenAI-compatible)

    private func buildPayload(prompt: String) -> [String: Any] {
        [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": 0.9,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
    }

    // MARK: - Network

    private func post(payload: [String: Any]) async throws -> Data {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody   = try JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json",               forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Secrets.claudeAPIKey)", forHTTPHeaderField: "Authorization")

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

    // MARK: - Parse Groq envelope → text string

    private func extractText(from data: Data) throws -> String {
        let envelope = try JSONDecoder().decode(GroqChatResponse.self, from: data)
        guard let text = envelope.firstContent else {
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
        case .invalidResponse:         return "Invalid response from Groq API."
        case .httpError(let c, let b): return "Groq API error \(c): \(b)"
        case .noTextContent:           return "Groq returned no text content."
        }
    }
}
