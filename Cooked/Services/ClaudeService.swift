import Foundation

// MARK: - GroqService (ClaudeService for internal compatibility)

final class ClaudeService {
    static let shared = ClaudeService()
    private init() {}

    private let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let model    = "llama-3.3-70b-versatile"

    // MARK: - Generate roast

    func generateRoast(score: DayScore, profile: UserProfile) async throws -> RoastResult {
        let prompt = buildPrompt(score: score, profile: profile)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json",                   forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Secrets.claudeAPIKey)",     forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 200,
            "temperature": 0.9,
            "messages": [
                ["role": "system", "content": systemPrompt(profile: profile)],
                ["role": "user",   "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClaudeError.httpError(http.statusCode, body)
        }

        let parsed = try JSONDecoder().decode(GroqChatResponse.self, from: data)
        guard let content = parsed.firstContent else {
            throw ClaudeError.noTextContent
        }

        return try RoastResult.decode(from: content)
    }

    // MARK: - Prompt building

    private func systemPrompt(profile: UserProfile) -> String {
        let censored = profile.uncensoredMode ? "" : " Keep it clean — no swearing."
        return "You are a brutally honest productivity coach. You roast people based on their screen time data.\(censored) Always respond ONLY with valid JSON: {\"roast\":\"...\",\"tip\":\"...\"}"
    }

    private func buildPrompt(score: DayScore, profile: UserProfile) -> String {
        let goalsList = profile.goals.filter { !$0.isEmpty }.joined(separator: "; ")
        return """
        Name: \(profile.name)
        Score: \(score.overall)/100
        Productive screen time: \(score.productiveFormatted)
        Wasted screen time: \(score.wastedFormatted)
        Top wasted app: \(score.topWastedApp.isEmpty ? "Unknown" : score.topWastedApp)
        Goals: \(goalsList.isEmpty ? "None set" : goalsList)
        Roast style: \(profile.roastStyle.displayName)

        Write a 2–3 sentence roast about their screen time. Be specific. Then give one concrete tip for tomorrow.
        """
    }
}

// MARK: - Errors (GroqChatResponse defined in RoastResult.swift)

enum ClaudeError: LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case noTextContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:        return "Invalid server response"
        case .httpError(let c, _):    return "Server error \(c)"
        case .noTextContent:          return "Empty response from AI"
        }
    }
}
