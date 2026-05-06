import Foundation

// MARK: - Demo fake data (remove before launch)

enum FakeData {

    static let score = DayScore(
        date:            Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        overall:         28,
        productiveTime:  1.5 * 3600,
        wastedTime:      8.5 * 3600,
        topWastedApp:    "TikTok",
        roast:           "4hrs on TikTok and somehow an hour on Wallet. Are you just checking how broke you are? Your Xcode was open for exactly 60 minutes, which is adorable. Put the phone down.",
        tip:             "Try keeping TikTok under 1hr tomorrow.",
        callouts: [
            Callout(type: .negative, emoji: "💀", text: "TikTok 4h"),
            Callout(type: .negative, emoji: "💀", text: "YouTube 2h"),
            Callout(type: .negative, emoji: "💀", text: "Instagram 1h 30m"),
            Callout(type: .negative, emoji: "💀", text: "Wallet 1h"),
            Callout(type: .positive, emoji: "🔥", text: "Xcode 1h"),
            Callout(type: .positive, emoji: "✅", text: "Notion 30m"),
        ]
    )

    static let profile: UserProfile = {
        let p = UserProfile(name: "Luka")
        p.goals = ["Build a startup", "Ship an app", "Stop doom-scrolling"]
        p.roastStyle = .savage
        p.uncensoredMode = true
        return p
    }()

    static let streak = 3

    static let apps: [(name: String, duration: TimeInterval, isGood: Bool)] = [
        ("TikTok",    4.0  * 3600, false),
        ("YouTube",   2.0  * 3600, false),
        ("Instagram", 1.5  * 3600, false),
        ("Wallet",    1.0  * 3600, false),
        ("Xcode",     1.0  * 3600, true),
        ("Notion",    0.5  * 3600, true),
    ]

    static let tips: [(emoji: String, text: String, good: Bool)] = [
        ("📵", "TikTok was 4h yesterday. Try staying under 1h today.", false),
        ("💸", "You spent 1h on Wallet. That's... concerning. Maybe check it once.", false),
        ("💻", "Xcode for 1h was solid. Double it today and you might actually ship something.", true),
    ]

    static let quote = "You said you want to build a startup. Every hour on TikTok is an hour your competitor is coding."

    static func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t / 3600)
        let m = Int((t.truncatingRemainder(dividingBy: 3600)) / 60)
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0            { return "\(h)h" }
        return "\(m)m"
    }
}
