import SwiftUI
import Charts

struct StatsView: View {
    @State private var appeared = false

    private let weekData: [(day: String, score: Int)] = [
        ("Mon", 45), ("Tue", 32), ("Wed", 28),
        ("Thu", 55), ("Fri", 62), ("Sat", 48), ("Sun", 28),
    ]

    private let appStats: [(name: String, emoji: String, daily: TimeInterval, trend: String, isGood: Bool)] = [
        ("TikTok",    "📱", 3.5  * 3600, "up",   false),
        ("YouTube",   "▶️",  2.0  * 3600, "down", false),
        ("Instagram", "📸", 1.5  * 3600, "flat", false),
        ("Xcode",     "🛠️",  0.75 * 3600, "up",   true),
        ("Notion",    "📝", 0.33 * 3600, "up",   true),
    ]

    private var isTrendingUp: Bool {
        (weekData.last?.score ?? 0) > (weekData.first?.score ?? 0)
    }

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()
            glows

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    Spacer().frame(height: DS.Space.sm)

                    Text("Your History")
                        .font(DS.Font.display(28))
                        .foregroundStyle(DS.Color.text1)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    chartCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    appBreakdown
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)

                    dayCallouts
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 28)

                    Spacer().frame(height: DS.Space.xxl)
                }
                .padding(.horizontal, DS.Space.lg)
            }
        }
        .onAppear {
            withAnimation(DS.Anim.spring.delay(0.05)) { appeared = true }
        }
    }

    // MARK: - Glows

    private var glows: some View {
        ZStack {
            RadialGradient(colors: [DS.Color.tealStart.opacity(0.06), .clear],
                           center: .init(x: 0.1, y: 0.08), startRadius: 0, endRadius: 260)
            RadialGradient(colors: [DS.Color.fireStart.opacity(0.06), .clear],
                           center: .init(x: 0.9, y: 0.08), startRadius: 0, endRadius: 260)
        }
        .ignoresSafeArea()
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SCORE TREND")
                        .font(DS.Font.label(9))
                        .foregroundStyle(DS.Color.text3)
                        .kerning(1.5)
                    Text("Last 7 days")
                        .font(DS.Font.display(16))
                        .foregroundStyle(DS.Color.text1)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: isTrendingUp ? "arrow.up" : "arrow.down")
                        .font(.system(size: 11, weight: .bold))
                    Text(isTrendingUp ? "Improving" : "Declining")
                        .font(DS.Font.label(11))
                }
                .if(isTrendingUp)  { $0.gradientText(DS.Gradient.teal) }
                .if(!isTrendingUp) { $0.gradientText(DS.Gradient.fire) }
            }

            Chart {
                ForEach(weekData, id: \.day) { item in
                    AreaMark(
                        x: .value("Day", item.day),
                        y: .value("Score", appeared ? item.score : 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: isTrendingUp
                                ? [DS.Color.tealStart.opacity(0.20), .clear]
                                : [DS.Color.fireStart.opacity(0.20), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Score", appeared ? item.score : 0)
                    )
                    .foregroundStyle(isTrendingUp ? DS.Color.tealStart : DS.Color.fireStart)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Score", appeared ? item.score : 0)
                    )
                    .foregroundStyle(isTrendingUp ? DS.Color.tealStart : DS.Color.fireStart)
                    .symbolSize(30)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(DS.Color.text3.opacity(0.25))
                    AxisValueLabel {
                        if let v = val.as(Int.self) {
                            Text("\(v)")
                                .font(DS.Font.body(10))
                                .foregroundStyle(DS.Color.text3)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { val in
                    AxisValueLabel {
                        if let s = val.as(String.self) {
                            Text(s)
                                .font(DS.Font.body(10))
                                .foregroundStyle(DS.Color.text3)
                        }
                    }
                }
            }
            .chartPlotStyle { plot in
                plot.background(DS.Color.bg.opacity(0.5))
            }
            .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.25), value: appeared)
            .frame(height: 180)
        }
        .padding(DS.Space.lg)
        .cardStyle()
    }

    // MARK: - App breakdown

    private var appBreakdown: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("APP BREAKDOWN")
                .font(DS.Font.label(10))
                .foregroundStyle(DS.Color.text3)
                .kerning(1.5)

            VStack(spacing: DS.Space.sm) {
                ForEach(appStats, id: \.name) { app in
                    appRow(app)
                }
            }
        }
    }

    private func appRow(
        _ app: (name: String, emoji: String, daily: TimeInterval, trend: String, isGood: Bool)
    ) -> some View {
        HStack(spacing: DS.Space.md) {
            Text(app.emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(
                    app.isGood
                        ? DS.Color.tealStart.opacity(0.10)
                        : DS.Color.fireStart.opacity(0.10)
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(DS.Font.label(14))
                    .foregroundStyle(DS.Color.text1)
                Text(app.isGood ? "Productive" : "Wasted")
                    .font(DS.Font.body(11))
                    .foregroundStyle(DS.Color.text3)
            }

            Spacer()

            HStack(spacing: 5) {
                Text(fmt(app.daily) + "/day")
                    .font(DS.Font.display(13))
                    .if(app.isGood)  { $0.gradientText(DS.Gradient.teal) }
                    .if(!app.isGood) { $0.gradientText(DS.Gradient.fire) }

                Image(systemName: trendIcon(app.trend, isGood: app.isGood))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(trendColor(app.trend, isGood: app.isGood))
            }
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    private func trendIcon(_ trend: String, isGood: Bool) -> String {
        switch trend {
        case "up":   return "arrow.up"
        case "down": return "arrow.down"
        default:     return "arrow.right"
        }
    }

    private func trendColor(_ trend: String, isGood: Bool) -> Color {
        switch trend {
        case "up":   return isGood ? DS.Color.tealStart : DS.Color.fireStart
        case "down": return isGood ? DS.Color.fireStart : DS.Color.tealStart
        default:     return DS.Color.text3
        }
    }

    // MARK: - Day callouts

    private var dayCallouts: some View {
        VStack(spacing: DS.Space.sm) {
            dayCard(label: "WORST DAY THIS WEEK", day: "Tuesday",
                    detail: "8h 30m wasted. Score: 28.",
                    grad: DS.Gradient.fire, accent: DS.Color.fireStart)
            dayCard(label: "BEST DAY THIS WEEK", day: "Friday",
                    detail: "2h wasted. Score: 62.",
                    grad: DS.Gradient.teal, accent: DS.Color.tealStart)
        }
    }

    private func dayCard(label: String, day: String, detail: String,
                         grad: LinearGradient, accent: Color) -> some View {
        HStack(spacing: DS.Space.md) {
            Rectangle().fill(accent).frame(width: 3).clipShape(Capsule())
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DS.Font.label(9)).foregroundStyle(DS.Color.text3).kerning(1.2)
                Text(day)
                    .font(DS.Font.display(16)).gradientText(grad)
                Text(detail)
                    .font(DS.Font.body(12)).foregroundStyle(DS.Color.text2)
            }
            Spacer()
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - Helpers

    private func fmt(_ t: TimeInterval) -> String {
        let h = Int(t / 3600); let m = Int((t.truncatingRemainder(dividingBy: 3600)) / 60)
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        return h > 0 ? "\(h)h" : "\(m)m"
    }
}

#Preview { StatsView() }
