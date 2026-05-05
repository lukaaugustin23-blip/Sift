import SwiftUI

enum DS {

    // MARK: - Colors

    enum Color {
        static let bg            = SwiftUI.Color(hex: "F5F1E8")
        static let bgSecondary   = SwiftUI.Color(hex: "E8E4DC")
        static let ink           = SwiftUI.Color(hex: "0A0A0A")
        static let inkSecondary  = SwiftUI.Color(red: 10/255, green: 10/255, blue: 10/255, opacity: 0.35)
        static let accent        = SwiftUI.Color(hex: "4F9CF9")
        static let danger        = SwiftUI.Color(hex: "E85D5D")
        static let dark          = SwiftUI.Color(hex: "0A0A0A")
        static let darkText      = SwiftUI.Color(hex: "F5F1E8")

        // Derived / semantic
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

    // MARK: - Spacing (base unit = 4pt)

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
        static let card:  CGFloat = 24
        static let badge: CGFloat = 14
        static let tag:   CGFloat = 6
        static let pill:  CGFloat = 999
    }

    // MARK: - Roast Card

    enum RoastCard {
        static let width:  CGFloat = 360
        static let badgeSize: CGFloat = 60
        static let barHeight: CGFloat = 5
    }

    // MARK: - Animation

    enum Animation {
        static let cardEntrance = SwiftUI.Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.6)
        static let barFill      = SwiftUI.Animation.timingCurve(0.16, 1, 0.3, 1, duration: 1.0).delay(0.4)
        static let buttonPress  = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
}
