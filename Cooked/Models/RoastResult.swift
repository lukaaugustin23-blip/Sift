import Foundation

// MARK: - RoastResult
// Transient struct — wraps Claude API JSON response.
// Never persisted directly; values are written into DayScore after receipt.

struct RoastResult: Codable {
    let roast: String
    let tip: String

    // MARK: - Decoding

    /// Decode Claude's raw response body.
    /// Handles both clean JSON and JSON embedded in markdown code fences.
    static func decode(from data: Data) throws -> RoastResult {
        // 1. Try direct JSON decode
        if let result = try? JSONDecoder().decode(RoastResult.self, from: data) {
            return result
        }

        // 2. Attempt to extract JSON from ```json ... ``` fence
        if let raw = String(data: data, encoding: .utf8) {
            let stripped = raw
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let strippedData = stripped.data(using: .utf8) {
                return try JSONDecoder().decode(RoastResult.self, from: strippedData)
            }
        }

        throw RoastDecodeError.malformedResponse
    }

    /// Decode from Anthropic message content string (the text block value).
    static func decode(from string: String) throws -> RoastResult {
        guard let data = string.data(using: .utf8) else {
            throw RoastDecodeError.malformedResponse
        }
        return try decode(from: data)
    }
}

// MARK: - Errors

enum RoastDecodeError: LocalizedError {
    case malformedResponse

    var errorDescription: String? {
        "Claude returned an unexpected response format. Will retry next roast."
    }
}

// MARK: - Anthropic API response envelope
// Used to pull the text content out of the full /v1/messages response.

struct AnthropicMessagesResponse: Codable {
    struct Content: Codable {
        let type: String
        let text: String?
    }
    let content: [Content]

    /// First text block from the response
    var firstText: String? {
        content.first(where: { $0.type == "text" })?.text
    }
}
