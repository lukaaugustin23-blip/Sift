import Foundation

// MARK: - RoastResult
// Transient struct — wraps Groq API JSON response.
// Never persisted directly; values are written into DayScore after receipt.

struct RoastResult: Codable {
    let roast: String
    let tip: String

    // MARK: - Decoding

    /// Decode from a raw string (the content field from Groq's message).
    /// Handles clean JSON and markdown-fenced JSON.
    static func decode(from string: String) throws -> RoastResult {
        let candidates = [
            string,
            string
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines),
        ]
        for candidate in candidates {
            if let data = candidate.data(using: .utf8),
               let result = try? JSONDecoder().decode(RoastResult.self, from: data) {
                return result
            }
        }
        throw RoastDecodeError.malformedResponse
    }
}

// MARK: - Errors

enum RoastDecodeError: LocalizedError {
    case malformedResponse

    var errorDescription: String? {
        "Groq returned an unexpected response format. Will retry next roast."
    }
}

// MARK: - Groq / OpenAI-compatible response envelope

struct GroqChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]

    /// Content string from the first choice
    var firstContent: String? { choices.first?.message.content }
}
