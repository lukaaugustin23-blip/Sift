import SwiftUI

// MARK: - Roast Style

enum RoastStyle: String, Codable, CaseIterable {
    case savage, disappointedParent, coach, sarcastic

    var displayName: String {
        switch self {
        case .savage:             return "Savage"
        case .disappointedParent: return "Disappointed Parent"
        case .coach:              return "Coach"
        case .sarcastic:          return "Sarcastic"
        }
    }

    var emoji: String {
        switch self {
        case .savage:             return "💀"
        case .disappointedParent: return "😞"
        case .coach:              return "📣"
        case .sarcastic:          return "🙄"
        }
    }

    var subtitle: String {
        switch self {
        case .savage:             return "No mercy. Every bad choice, exposed."
        case .disappointedParent: return "I expected so much more from you."
        case .coach:              return "Furious, but still believes in you."
        case .sarcastic:          return "Dripping in irony. Painfully accurate."
        }
    }
}

// MARK: - Grade

enum Grade: String {
    case a = "A", b = "B", c = "C", d = "D", f = "F"

    static func from(_ score: Int) -> Grade {
        switch score {
        case 90...100: return .a
        case 75..<90:  return .b
        case 60..<75:  return .c
        case 40..<60:  return .d
        default:       return .f
        }
    }

    var label: String {
        switch self {
        case .a: return "EXCELLENT"
        case .b: return "SOLID"
        case .c: return "AVERAGE"
        case .d: return "ROUGH"
        case .f: return "COOKED 💀"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .a, .b: return DS.Color.accent
        case .c:     return DS.Color.ink
        case .d, .f: return DS.Color.danger
        }
    }
}

// MARK: - Callout

enum CalloutType: String, Codable { case positive, negative }

struct Callout: Codable, Identifiable {
    var id = UUID()
    var type: CalloutType
    var emoji: String
    var text: String
}
