import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Font {
    static func syne(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Syne-ExtraBold", size: size)
    }

    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .light:
            return .custom("DMSans-Light", size: size)
        case .medium:
            return .custom("DMSans-Medium", size: size)
        default:
            return .custom("DMSans-Regular", size: size)
        }
    }

    static func spaceMono(_ size: CGFloat, bold: Bool = false) -> Font {
        bold
            ? .custom("SpaceMono-Bold", size: size)
            : .custom("SpaceMono-Regular", size: size)
    }
}

extension View {
    func labelStyle() -> some View {
        self
            .font(.spaceMono(10))
            .textCase(.uppercase)
            .tracking(3)
    }
}
