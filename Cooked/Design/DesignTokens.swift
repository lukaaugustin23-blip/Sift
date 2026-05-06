import SwiftUI

// MARK: - Design System

enum DS {

    // MARK: - Colors

    enum Color {
        // Backgrounds
        static let bg         = SwiftUI.Color(hex: "0D0D12")
        static let card       = SwiftUI.Color(hex: "161620")
        static let cardBorder = SwiftUI.Color.white.opacity(0.055)

        // Text hierarchy
        static let text1 = SwiftUI.Color.white
        static let text2 = SwiftUI.Color.white.opacity(0.55)
        static let text3 = SwiftUI.Color.white.opacity(0.25)

        // Teal — productive, good, positive ONLY
        static let tealStart = SwiftUI.Color(hex: "00E5A0")
        static let tealEnd   = SwiftUI.Color(hex: "00C4E0")

        // Fire — wasted, bad, buttons, brand accent, streak ONLY
        static let fireStart = SwiftUI.Color(hex: "FF4500")
        static let fireEnd   = SwiftUI.Color(hex: "FFB347")
    }

    // MARK: - Gradients

    enum Gradient {
        static let teal = LinearGradient(
            colors: [DS.Color.tealStart, DS.Color.tealEnd],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let fire = LinearGradient(
            colors: [DS.Color.fireStart, DS.Color.fireEnd],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: - Typography (Plus Jakarta Sans only)

    enum Font {
        // 800 — logo, titles, score numbers, badge, streak numbers
        static func display(_ size: CGFloat) -> SwiftUI.Font {
            .custom("PlusJakartaSans-ExtraBold", size: size)
        }
        // 600 — labels, buttons, tags
        static func label(_ size: CGFloat) -> SwiftUI.Font {
            .custom("PlusJakartaSans-SemiBold", size: size)
        }
        // 400 — body text
        static func body(_ size: CGFloat) -> SwiftUI.Font {
            .custom("PlusJakartaSans-Regular", size: size)
        }
        // 400 italic — roast text
        static func bodyItalic(_ size: CGFloat) -> SwiftUI.Font {
            .custom("PlusJakartaSans-Italic", size: size)
        }
        // 600 italic
        static func labelItalic(_ size: CGFloat) -> SwiftUI.Font {
            .custom("PlusJakartaSans-SemiBoldItalic", size: size)
        }
        // 800 italic
        static func displayItalic(_ size: CGFloat) -> SwiftUI.Font {
            .custom("PlusJakartaSans-ExtraBoldItalic", size: size)
        }
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
        static let inner: CGFloat = 16
        static let badge: CGFloat = 16
        static let tag:   CGFloat = 8
        static let pill:  CGFloat = 999
    }

    // MARK: - Animation

    enum Anim {
        static let spring  = SwiftUI.Animation.spring(response: 0.55, dampingFraction: 0.78)
        static let slide   = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.82)
        static let fast    = SwiftUI.Animation.spring(response: 0.3,  dampingFraction: 0.85)
    }
}

// MARK: - View helpers

extension View {
    /// Standard dark card: card bg, border, 20pt radius, shadow
    func cardStyle() -> some View {
        self
            .background(DS.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .strokeBorder(DS.Color.cardBorder, lineWidth: 1)
            )
    }

    /// Inner card: same but 16pt radius
    func innerCardStyle() -> some View {
        self
            .background(DS.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.inner))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.inner)
                    .strokeBorder(DS.Color.cardBorder, lineWidth: 1)
            )
    }

    /// Fire gradient pill button
    func fireButtonStyle() -> some View {
        self
            .font(DS.Font.label(15))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.md + 2)
            .background(DS.Gradient.fire)
            .clipShape(Capsule())
    }
}

// MARK: - Gradient text helper

extension Text {
    func gradientForeground(_ gradient: LinearGradient) -> some View {
        self.overlay(gradient).mask(self)
    }
}
