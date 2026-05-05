import SwiftUI

enum DS {

    // MARK: - Colors

    enum Color {
        static let bg            = SwiftUI.Color(hex: "F5F1E8")   // warm cream — all screen backgrounds
        static let surface       = SwiftUI.Color.white              // card surfaces
        static let bgSecondary   = SwiftUI.Color(hex: "E8E4DC")   // subtle secondary surface
        static let ink           = SwiftUI.Color(hex: "0A0A0A")   // primary text
        static let inkSecondary  = SwiftUI.Color(red: 10/255, green: 10/255, blue: 10/255, opacity: 0.38)
        static let accent        = SwiftUI.Color(hex: "4F9CF9")   // blue — productive
        static let danger        = SwiftUI.Color(hex: "E85D5D")   // red — wasted
        static let dark          = SwiftUI.Color(hex: "0A0A0A")
        static let darkText      = SwiftUI.Color(hex: "F5F1E8")

        // Semantic
        static let calloutPositiveBg = accent.opacity(0.10)
        static let calloutNegativeBg = danger.opacity(0.10)
        static let trackBg           = SwiftUI.Color(hex: "0A0A0A").opacity(0.06)
    }

    // MARK: - Typography

    enum Font {
        static func display(_ size: CGFloat = 88) -> SwiftUI.Font  { .syne(size) }
        static func hero(_ size: CGFloat = 52) -> SwiftUI.Font     { .syne(size) }
        static func heading(_ size: CGFloat = 24) -> SwiftUI.Font  { .syne(size) }
        static func subheading(_ size: CGFloat = 18) -> SwiftUI.Font { .syne(size) }
        static func body(_ size: CGFloat = 14) -> SwiftUI.Font     { .dmSans(size) }
        static func bodyMedium(_ size: CGFloat = 14) -> SwiftUI.Font { .dmSans(size, weight: .medium) }
        static func label(_ size: CGFloat = 10) -> SwiftUI.Font    { .spaceMono(size) }
        static func data(_ size: CGFloat = 12) -> SwiftUI.Font     { .spaceMono(size, bold: true) }
    }

    // MARK: - Spacing (4pt base)

    enum Space {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Radius

    enum Radius {
        static let card:  CGFloat = 20
        static let badge: CGFloat = 14
        static let tag:   CGFloat = 10
        static let pill:  CGFloat = 999
    }

    // MARK: - Card constants

    enum RoastCard {
        static let width:    CGFloat = 360
        static let badgeSize: CGFloat = 60
        static let barHeight: CGFloat = 6
    }

    // MARK: - Animation

    enum Animation {
        static let standard   = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let cardEntrance = SwiftUI.Animation.spring(response: 0.65, dampingFraction: 0.78)
        static let barFill    = SwiftUI.Animation.spring(response: 1.0, dampingFraction: 0.75).delay(0.35)
        static let buttonPress = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
    }
}

// MARK: - Card modifier

extension View {
    /// Standard surface card: white bg, 20pt radius, soft shadow
    func cardStyle() -> some View {
        self
            .background(DS.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
    }

    /// Primary button: full-width, ink bg, cream text, pill shape
    func primaryButtonStyle() -> some View {
        self
            .font(DS.Font.label(11))
            .foregroundStyle(DS.Color.darkText)
            .tracking(3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.lg)
            .background(DS.Color.ink)
            .clipShape(Capsule())
    }

    // labelStyle() defined in Extensions.swift — not duplicated here
}
