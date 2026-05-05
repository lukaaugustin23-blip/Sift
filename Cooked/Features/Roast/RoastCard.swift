import SwiftUI

// MARK: - RoastCard
// Self-contained — no @Query/@Environment so ImageRenderer can render it cleanly.

struct RoastCard: View {
    let score:    DayScore
    let profile:  UserProfile
    let streak:   Int
    var isForExport: Bool = false

    @State private var barsAnimated = false

    static let cardWidth: CGFloat = 360

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: score.date).uppercased()
    }

    private var gradeValue: Grade { Grade.from(score.overall) }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            scoreSection
            roastSection
            statsRow
            barsSection
            calloutsSection
            bottomRow
        }
        .frame(width: Self.cardWidth)
        .background(DS.Color.bg)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 24, y: 12)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(DS.Animation.barFill) { barsAnimated = true }
            }
        }
    }

    // MARK: - Header bar (black)

    private var headerBar: some View {
        HStack {
            Text("cooked")
                .font(DS.Font.subheading(16))
                .foregroundStyle(DS.Color.darkText)
            Spacer()
            Text(dateString)
                .font(DS.Font.label(9))
                .foregroundStyle(DS.Color.darkText.opacity(0.6))
                .tracking(2)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.dark)
    }

    // MARK: - Score section

    private var scoreSection: some View {
        HStack(alignment: .bottom, spacing: DS.Space.md) {
            // Big score number
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(score.overall)")
                    .font(DS.Font.display(88))
                    .foregroundStyle(DS.Color.ink)
                    .contentTransition(.numericText())
                Text("/100")
                    .font(DS.Font.body(16))
                    .foregroundStyle(DS.Color.inkSecondary)
                    .padding(.bottom, 14)
            }

            Spacer()

            // Grade badge
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.badge)
                    .fill(DS.Color.dark)
                    .frame(
                        width:  DS.RoastCard.badgeSize,
                        height: DS.RoastCard.badgeSize
                    )
                Text(gradeValue.rawValue)
                    .font(DS.Font.display(32))
                    .foregroundStyle(DS.Color.accent)
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.top, DS.Space.lg)
        .padding(.bottom, DS.Space.sm)
    }

    // MARK: - Roast text

    private var roastSection: some View {
        HStack(alignment: .top, spacing: DS.Space.sm) {
            Rectangle()
                .fill(DS.Color.accent)
                .frame(width: 3)
                .clipShape(Capsule())

            Text(score.roast.isEmpty ? "Your roast will appear here after processing." : score.roast)
                .font(.custom("DMSans-Regular", size: 14).italic())
                .foregroundStyle(DS.Color.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
    }

    // MARK: - Stats row (3 columns)

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatColumn(
                label: "PRODUCTIVE",
                value: scoreLabel(score.screenScore),
                color: DS.Color.accent
            )
            Divider()
                .frame(height: 32)
                .overlay(DS.Color.inkSecondary.opacity(0.2))
            StatColumn(
                label: "WASTED",
                value: scoreLabel(100 - score.screenScore),
                color: DS.Color.danger
            )
            Divider()
                .frame(height: 32)
                .overlay(DS.Color.inkSecondary.opacity(0.2))
            StatColumn(
                label: "TOP CAT",
                value: topCategory,
                color: DS.Color.ink
            )
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.sm)
        .background(DS.Color.bgSecondary)
    }

    private func scoreLabel(_ s: Int) -> String { "\(s)%" }

    private var topCategory: String {
        // Highest sub-score
        let cats = [
            ("Sleep",    score.sleepScore),
            ("Physical", score.physicalScore),
            ("Screen",   score.screenScore),
            ("School",   score.schoolScore),
            ("Homework", score.homeworkScore),
        ]
        return cats.max(by: { $0.1 < $1.1 })?.0 ?? "—"
    }

    // MARK: - Bars (productive vs wasted)

    private var barsSection: some View {
        VStack(spacing: DS.Space.xs) {
            ScoreBar(
                label: "Productive",
                fill: barsAnimated ? Double(score.screenScore) / 100 : 0,
                color: DS.Color.accent
            )
            ScoreBar(
                label: "Wasted",
                fill: barsAnimated ? Double(100 - score.screenScore) / 100 : 0,
                color: DS.Color.danger
            )
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.sm)
    }

    // MARK: - Callouts

    private var calloutsSection: some View {
        FlowRowLayout(spacing: DS.Space.xs) {
            ForEach(score.callouts) { callout in
                CalloutTag(callout: callout)
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.bottom, DS.Space.sm)
    }

    // MARK: - Bottom row (streak)

    private var bottomRow: some View {
        HStack {
            if streak > 0 {
                HStack(spacing: DS.Space.xs) {
                    Text("🔥")
                    Text("\(streak) day streak")
                        .font(DS.Font.data(11))
                        .foregroundStyle(DS.Color.ink)
                }
            } else {
                Text("0 days — start tonight")
                    .font(DS.Font.data(11))
                    .foregroundStyle(DS.Color.inkSecondary)
            }
            Spacer()
            Text("cooked")
                .font(DS.Font.label(8))
                .foregroundStyle(DS.Color.inkSecondary)
                .tracking(2)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.bgSecondary)
    }
}

// MARK: - Stat Column

private struct StatColumn: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(DS.Font.label(7))
                .foregroundStyle(DS.Color.inkSecondary)
                .tracking(2)
            Text(value)
                .font(DS.Font.data(13))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
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
                .font(DS.Font.label(8))
                .foregroundStyle(DS.Color.inkSecondary)
                .tracking(2)
                .frame(width: 72, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DS.Radius.pill)
                        .fill(DS.Color.trackBg)
                        .frame(height: DS.RoastCard.barHeight)
                    RoundedRectangle(cornerRadius: DS.Radius.pill)
                        .fill(color)
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
            Text(callout.emoji).font(.system(size: 11))
            Text(callout.text.uppercased())
                .font(DS.Font.label(7))
                .foregroundStyle(callout.type == .positive ? DS.Color.accent : DS.Color.danger)
                .tracking(1.5)
        }
        .padding(.horizontal, DS.Space.sm)
        .padding(.vertical, 5)
        .background(
            callout.type == .positive
                ? DS.Color.calloutPositiveBg
                : DS.Color.calloutNegativeBg
        )
        .clipShape(Capsule())
    }
}

// MARK: - Flow row layout (wrapping)

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
        return CGSize(width: maxW, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}

#Preview {
    let score = DayScore()
    score.overall       = 72
    score.sleepScore    = 80
    score.physicalScore = 90
    score.screenScore   = 60
    score.schoolScore   = 70
    score.homeworkScore = 55
    score.roast = "You hit the gym but spent 3 hours on TikTok. The weights don't cancel out the scroll. Tomorrow, close the app before you hit the couch."
    score.tip   = "Put your phone charger across the room tonight."
    score.callouts = [
        Callout(type: .positive, emoji: "🔥", text: "Gym at 4pm"),
        Callout(type: .negative, emoji: "💀", text: "Doomscrolled in bed"),
        Callout(type: .positive, emoji: "✅", text: "Homework done"),
    ]

    return ScrollView {
        RoastCard(score: score, profile: UserProfile(name: "Luka"), streak: 7)
            .padding()
    }
    .background(DS.Color.bgSecondary)
}
