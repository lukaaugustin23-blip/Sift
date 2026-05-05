import SwiftUI

struct RoastCard: View {
    let score:       DayScore
    let profile:     UserProfile
    let streak:      Int
    var isForExport: Bool = false

    static let cardWidth:  CGFloat = 360
    static let cardHeight: CGFloat = 680

    private var scoreGradient: LinearGradient {
        score.overall >= 60 ? DS.Gradient.teal : DS.Gradient.fire
    }
    private var borderColor: Color {
        score.overall >= 60 ? DS.Color.tealStart : DS.Color.fireStart
    }

    var body: some View {
        ZStack {
            DS.Color.bg

            VStack(spacing: 0) {
                // Header bar
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        // Score section
                        scoreSection

                        // Roast section
                        roastSection

                        // Stats + bars
                        statsSection
                        barsSection

                        // Streak
                        streakSection
                    }
                    .padding(DS.Space.lg)
                }

                // Share bar
                bottomBar
            }
        }
        .frame(width: isForExport ? RoastCard.cardWidth : nil,
               height: isForExport ? RoastCard.cardHeight : nil)
        .clipShape(RoundedRectangle(cornerRadius: isForExport ? 0 : DS.Radius.card))
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            HStack(spacing: 0) {
                Text("cook")
                    .font(DS.Font.display(18))
                    .foregroundStyle(DS.Color.text1)
                Text("ed.")
                    .font(DS.Font.display(18))
                    .gradientText(DS.Gradient.fire)
            }
            Spacer()
            Text(score.date, format: .dateTime.month(.abbreviated).day().year())
                .font(DS.Font.body(12))
                .foregroundStyle(DS.Color.text3)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.card)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.Color.cardBorder).frame(height: 1)
        }
    }

    // MARK: - Score

    private var scoreSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(score.overall)")
                        .font(DS.Font.display(80))
                        .gradientText(scoreGradient)
                    Text("/100")
                        .font(DS.Font.display(18))
                        .foregroundStyle(DS.Color.text3)
                        .padding(.bottom, 10)
                }
                Text(score.grade == "A" || score.grade == "B" ? "Decent work." : "Rough day.")
                    .font(DS.Font.label(10))
                    .foregroundStyle(DS.Color.text3)
                    .kerning(1)
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.badge)
                    .fill(scoreGradient)
                    .frame(width: 58, height: 58)
                Text(score.grade)
                    .font(DS.Font.display(28))
                    .foregroundStyle(.white)
            }
            .shadow(color: borderColor.opacity(0.4), radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Roast

    private var roastSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("TODAY'S ROAST")
                .font(DS.Font.label(9))
                .gradientText(DS.Gradient.fire)
                .kerning(1.5)

            HStack(alignment: .top, spacing: DS.Space.sm) {
                Rectangle()
                    .fill(borderColor)
                    .frame(width: 2)
                Text(score.roast.isEmpty ? "Your screen time data is in." : score.roast)
                    .font(DS.Font.bodyItalic(13.5))
                    .foregroundStyle(DS.Color.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !score.tip.isEmpty {
                Text("💡 \(score.tip)")
                    .font(DS.Font.body(12))
                    .foregroundStyle(DS.Color.text3)
                    .padding(DS.Space.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.Color.tealStart.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
            }
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: DS.Space.sm) {
            miniStat(label: "PRODUCTIVE", value: score.productiveFormatted, gradient: DS.Gradient.teal)
            miniStat(label: "WASTED",     value: score.wastedFormatted,     gradient: DS.Gradient.fire)
            miniStat(label: "SCORE",      value: "\(score.overall)%",       gradient: scoreGradient)
        }
    }

    private func miniStat(label: String, value: String, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DS.Font.label(8))
                .foregroundStyle(DS.Color.text3)
                .kerning(1)
            Text(value)
                .font(DS.Font.display(13))
                .gradientText(gradient)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - Bars

    private var barsSection: some View {
        VStack(spacing: DS.Space.md) {
            cardBar(
                label: "Productive",
                value: score.productiveFormatted,
                ratio: CGFloat(score.productiveTime / max(score.totalScreenTime, 1)),
                gradient: DS.Gradient.teal
            )
            Divider().background(DS.Color.cardBorder)
            cardBar(
                label: "Wasted",
                value: score.wastedFormatted,
                ratio: CGFloat(score.wastedTime / max(score.totalScreenTime, 1)),
                gradient: DS.Gradient.fire
            )
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    private func cardBar(label: String, value: String, ratio: CGFloat, gradient: LinearGradient) -> some View {
        VStack(spacing: DS.Space.sm) {
            HStack {
                Text(label).font(DS.Font.label(11)).foregroundStyle(DS.Color.text2)
                Spacer()
                Text(value).font(DS.Font.label(11)).foregroundStyle(DS.Color.text2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Color.text3.opacity(0.12)).frame(height: 6)
                    Capsule().fill(gradient).frame(width: max(geo.size.width * ratio, ratio > 0 ? 6 : 0), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Streak

    private var streakSection: some View {
        HStack(spacing: DS.Space.sm) {
            Text("🔥").font(.system(size: 20))
            Text("\(streak)").font(DS.Font.display(16)).gradientText(DS.Gradient.fire)
            Text("day streak").font(DS.Font.body(13)).foregroundStyle(DS.Color.text3)
            Spacer()
            Text("cooked.app")
                .font(DS.Font.label(9))
                .foregroundStyle(DS.Color.text3)
                .kerning(1)
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        EmptyView()
    }
}

#Preview {
    let s = DayScore(overall: 72, productiveTime: 7200, wastedTime: 5400,
                     roast: "You spent more time watching strangers than touching grass.",
                     tip: "Delete TikTok from your home screen tonight.")
    return RoastCard(score: s, profile: UserProfile(name: "Luka"), streak: 5)
        .background(DS.Color.bg)
}
