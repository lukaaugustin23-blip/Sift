import SwiftUI

struct SubScoresView: View {
    let score: DayScore

    @State private var revealedCount: Int = 0

    private let categories: [(name: String, emoji: String, keyPath: KeyPath<DayScore, Int>)] = [
        ("Sleep",    "😴", \.sleepScore),
        ("Physical", "💪", \.physicalScore),
        ("Screen",   "📱", \.screenScore),
        ("School",   "📚", \.schoolScore),
        ("Homework", "✏️", \.homeworkScore),
    ]

    private let weights = ["25%", "20%", "20%", "20%", "15%"]

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            // Section header
            HStack {
                Text("BREAKDOWN")
                    .labelStyle()
                    .foregroundStyle(DS.Color.inkSecondary)
                Spacer()
                Text("WEIGHT")
                    .labelStyle()
                    .foregroundStyle(DS.Color.inkSecondary)
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal, DS.Space.lg)

            // Category rows
            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.offset) { i, cat in
                    SubScoreRow(
                        name:    cat.name,
                        emoji:   cat.emoji,
                        score:   score[keyPath: cat.keyPath],
                        weight:  weights[i],
                        animate: revealedCount > i
                    )

                    if i < categories.count - 1 {
                        Divider()
                            .overlay(DS.Color.inkSecondary.opacity(0.1))
                            .padding(.leading, DS.Space.lg)
                    }
                }
            }
            .background(DS.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
            .padding(.horizontal, DS.Space.lg)

            // Overall recap
            overallRow
        }
        .onAppear { staggerReveal() }
    }

    // MARK: - Overall row

    private var overallRow: some View {
        HStack {
            HStack(spacing: DS.Space.xs) {
                Text("OVERALL")
                    .labelStyle()
                    .foregroundStyle(DS.Color.ink)
                Text("·")
                    .foregroundStyle(DS.Color.inkSecondary)
                Text(Grade.from(score.overall).rawValue)
                    .font(DS.Font.data(13))
                    .foregroundStyle(DS.Color.accent)
            }
            Spacer()
            Text("\(score.overall)")
                .font(DS.Font.data(18))
                .foregroundStyle(DS.Color.ink)
            Text("/100")
                .font(DS.Font.body(12))
                .foregroundStyle(DS.Color.inkSecondary)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.dark)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
        .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Staggered reveal (80ms between each)

    private func staggerReveal() {
        for i in 0..<categories.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.08) {
                withAnimation(DS.Animation.barFill) {
                    revealedCount = i + 1
                }
            }
        }
    }
}

// MARK: - Single sub-score row

private struct SubScoreRow: View {
    let name:    String
    let emoji:   String
    let score:   Int
    let weight:  String
    let animate: Bool

    private var fill: Double { Double(score) / 100 }
    private var barColor: Color { score >= 50 ? DS.Color.accent : DS.Color.danger }

    var body: some View {
        HStack(spacing: DS.Space.md) {
            // Emoji
            Text(emoji)
                .font(.system(size: 16))
                .frame(width: 24)

            // Name + bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name.uppercased())
                        .font(DS.Font.label(9))
                        .foregroundStyle(DS.Color.ink)
                        .tracking(3)
                    Spacer()
                    Text("\(score)")
                        .font(DS.Font.data(13))
                        .foregroundStyle(barColor)
                        .contentTransition(.numericText())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: DS.Radius.pill)
                            .fill(DS.Color.trackBg)
                            .frame(height: DS.RoastCard.barHeight)
                        RoundedRectangle(cornerRadius: DS.Radius.pill)
                            .fill(barColor)
                            .frame(
                                width: geo.size.width * (animate ? max(0, min(1, fill)) : 0),
                                height: DS.RoastCard.barHeight
                            )
                            .animation(DS.Animation.barFill, value: animate)
                    }
                }
                .frame(height: DS.RoastCard.barHeight)
            }

            // Weight label
            Text(weight)
                .font(DS.Font.data(10))
                .foregroundStyle(DS.Color.inkSecondary)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.md)
    }
}

#Preview {
    let score = DayScore()
    score.overall = 72; score.sleepScore = 80; score.physicalScore = 90
    score.screenScore = 60; score.schoolScore = 70; score.homeworkScore = 55
    return SubScoresView(score: score)
        .background(DS.Color.bg)
}
