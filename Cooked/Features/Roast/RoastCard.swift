import SwiftUI

// MARK: - RoastCard
// Self-contained — no @Query/@Environment. Safe for ImageRenderer.

struct RoastCard: View {
    let score:       DayScore
    let profile:     UserProfile
    let streak:      Int
    var isForExport: Bool = false

    @State private var barsAnimated = false

    static let cardWidth: CGFloat = 360

    private var dateString: String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        return f.string(from: score.date).uppercased()
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            scoreSection
            roastSection
            statsRow
            barsSection
            if !score.callouts.isEmpty { calloutsSection }
            bottomRow
        }
        .frame(width: Self.cardWidth)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .shadow(color: .black.opacity(0.12), radius: 32, x: 0, y: 12)
        .onAppear {
            if isForExport { barsAnimated = true; return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(DS.Animation.barFill) { barsAnimated = true }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("cooked.")
                .font(DS.Font.subheading(15))
                .foregroundStyle(DS.Color.darkText)
            Spacer()
            Text(dateString)
                .font(DS.Font.label(8))
                .foregroundStyle(DS.Color.darkText.opacity(0.55))
                .tracking(2)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.ink)
    }

    // MARK: - Score

    private var scoreSection: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Number
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(score.overall)")
                    .font(DS.Font.display(80))
                    .foregroundStyle(DS.Color.ink)
                    .contentTransition(.numericText())
                Text("/100")
                    .font(DS.Font.body(14))
                    .foregroundStyle(DS.Color.inkSecondary)
                    .padding(.bottom, 11)
            }

            Spacer()

            // Grade badge
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(DS.Color.ink)
                    .frame(width: DS.RoastCard.badgeSize, height: DS.RoastCard.badgeSize)
                Text(score.grade)
                    .font(DS.Font.display(32))
                    .foregroundStyle(DS.Color.accent)
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.top, DS.Space.lg)
        .padding(.bottom, DS.Space.xs)
    }

    // MARK: - Roast text

    private var roastSection: some View {
        HStack(alignment: .top, spacing: DS.Space.sm) {
            Rectangle()
                .fill(DS.Color.accent)
                .frame(width: 3)
                .clipShape(Capsule())

            Text(score.roast.isEmpty ? "Your daily roast will appear here." : score.roast)
                .font(.custom("DMSans-Regular", size: 13).italic())
                .foregroundStyle(DS.Color.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(Color.black.opacity(0.025))
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCol(label: "PRODUCTIVE", value: score.productiveFormatted, color: DS.Color.accent)
            Divider().frame(height: 30).overlay(Color.black.opacity(0.07))
            statCol(label: "WASTED",     value: score.wastedFormatted,     color: DS.Color.danger)
            Divider().frame(height: 30).overlay(Color.black.opacity(0.07))
            statCol(label: "TOP APP",    value: shortApp(score.topWastedApp), color: DS.Color.ink)
        }
        .padding(.vertical, DS.Space.sm)
        .background(Color.black.opacity(0.03))
    }

    private func statCol(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(DS.Font.label(7))
                .foregroundStyle(DS.Color.inkSecondary)
                .tracking(2)
            Text(value.isEmpty ? "—" : value)
                .font(DS.Font.data(12))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func shortApp(_ bundleId: String) -> String {
        let map: [String: String] = [
            "com.zhiliaoapp.musically": "TikTok",
            "com.burbn.instagram": "Instagram",
            "com.google.ios.youtube": "YouTube",
            "com.atebits.Tweetie2": "Twitter",
            "com.netflix.Netflix": "Netflix",
            "com.reddit.Reddit": "Reddit",
        ]
        if bundleId.isEmpty { return "—" }
        return map[bundleId] ?? (bundleId.components(separatedBy: ".").last ?? bundleId)
    }

    // MARK: - Bars

    private var barsSection: some View {
        VStack(spacing: DS.Space.xs + 2) {
            ScoreBar(
                label: "Productive",
                fill: barsAnimated ? score.productiveRatio : 0,
                color: DS.Color.accent
            )
            ScoreBar(
                label: "Wasted",
                fill: barsAnimated ? (score.totalScreenTime > 0 ? score.wastedTime / score.totalScreenTime : 0) : 0,
                color: DS.Color.danger
            )
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.sm)
    }

    // MARK: - Callouts

    private var calloutsSection: some View {
        FlowRowLayout(spacing: DS.Space.xs) {
            ForEach(score.callouts) { c in
                CalloutTag(callout: c)
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.bottom, DS.Space.sm)
    }

    // MARK: - Bottom row

    private var bottomRow: some View {
        HStack {
            if streak > 0 {
                HStack(spacing: DS.Space.xs) {
                    Text("🔥")
                    Text("\(streak) day streak")
                        .font(DS.Font.data(10))
                        .foregroundStyle(DS.Color.ink)
                }
            } else {
                Text("0 days — start tonight")
                    .font(DS.Font.data(10))
                    .foregroundStyle(DS.Color.inkSecondary)
            }
            Spacer()
            Text("cooked.")
                .font(DS.Font.label(7))
                .foregroundStyle(DS.Color.inkSecondary)
                .tracking(2)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(Color.black.opacity(0.03))
    }
}

// MARK: - Score Bar

private struct ScoreBar: View {
    let label: String
    let fill:  Double
    let color: Color

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Text(label.uppercased())
                .font(DS.Font.label(7))
                .foregroundStyle(DS.Color.inkSecondary)
                .tracking(2)
                .frame(width: 72, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Color.trackBg)
                        .frame(height: DS.RoastCard.barHeight)
                    Capsule().fill(color)
                        .frame(
                            width: geo.size.width * max(0, min(1, fill)),
                            height: DS.RoastCard.barHeight
                        )
                        .animation(DS.Animation.barFill, value: fill)
                }
            }
            .frame(height: DS.RoastCard.barHeight)
        }
    }
}

// MARK: - Callout Tag

private struct CalloutTag: View {
    let callout: Callout
    var body: some View {
        HStack(spacing: 4) {
            Text(callout.emoji).font(.system(size: 10))
            Text(callout.text.uppercased())
                .font(DS.Font.label(7))
                .foregroundStyle(callout.type == .positive ? DS.Color.accent : DS.Color.danger)
                .tracking(1.5)
        }
        .padding(.horizontal, DS.Space.sm)
        .padding(.vertical, 5)
        .background(callout.type == .positive ? DS.Color.calloutPositiveBg : DS.Color.calloutNegativeBg)
        .clipShape(Capsule())
    }
}

// MARK: - Flow Layout

private struct FlowRowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > maxW, x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return .init(width: maxW, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            sv.place(at: .init(x: x, y: y), proposal: .unspecified)
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}

#Preview {
    let s = DayScore(overall: 72, productiveTime: 7200, wastedTime: 5400, topWastedApp: "com.zhiliaoapp.musically",
                     roast: "You spent more time on TikTok than on anything productive. The algorithm won today.",
                     tip: "Delete TikTok from your home screen tonight.")
    s.callouts = [Callout(type: .positive, emoji: "✅", text: "2h productive"),
                  Callout(type: .negative, emoji: "⏱️", text: "1.5h wasted")]
    return ScrollView { RoastCard(score: s, profile: UserProfile(name: "Luka"), streak: 7).padding() }
        .background(DS.Color.bg)
}
