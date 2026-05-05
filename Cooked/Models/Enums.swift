import Foundation

// MARK: - RoastStyle

enum RoastStyle: String, Codable, CaseIterable {
    case savage             = "savage"
    case disappointedParent = "disappointedParent"
    case coach              = "coach"
    case sarcastic          = "sarcastic"

    var displayName: String {
        switch self {
        case .savage:             return "Savage"
        case .disappointedParent: return "Disappointed Parent"
        case .coach:              return "Coach"
        case .sarcastic:          return "Sarcastic"
        }
    }

    var promptInstruction: String {
        switch self {
        case .savage:             return "Be brutal, no mercy, pull no punches."
        case .disappointedParent: return "Sound like a deeply disappointed parent who expected so much more."
        case .coach:              return "Sound like an intense coach who believes in them but is furious right now."
        case .sarcastic:          return "Dripping sarcasm, maximum irony."
        }
    }
}

// MARK: - PeriodQuality

enum PeriodQuality: String, Codable {
    case productive
    case wasted
}

// MARK: - Grade

enum Grade: String {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"

    static func from(_ score: Int) -> Grade {
        switch score {
        case 90...100: return .a
        case 75...89:  return .b
        case 60...74:  return .c
        case 50...59:  return .d
        default:       return .f
        }
    }
}

// MARK: - CalloutType

enum CalloutType: String, Codable {
    case positive
    case negative
}
