import SwiftUI

// MARK: - Category progress model

struct CategoryProgress: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let fill: Double      // 0.0 – 1.0
    let isLogged: Bool
    let status: String
}

// MARK: - TodayProgressView

struct TodayProgressView: View {
    let categories: [CategoryProgress]
    var onTap: ((CategoryProgress) -> Void)? = nil

    @State private var animatedFills: [UUID: Double] = [:]

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            ForEach(categories) { cat in
                CategoryRow(
                    category: cat,
                    animatedFill: animatedFills[cat.id] ?? 0
                ) {
                    onTap?(cat)
                }
            }
        }
        .onAppear {
            // Stagger bar animations
            for (i, cat) in categories.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.08) {
                    withAnimation(DS.Animation.barFill) {
                        animatedFills[cat.id] = cat.fill
                    }
                }
            }
        }
        .onChange(of: categories.map(\.fill)) { _, _ in
            // Re-animate when new log saved
            for (i, cat) in categories.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                    withAnimation(DS.Animation.barFill) {
                        animatedFills[cat.id] = cat.fill
                    }
                }
            }
        }
    }
}

// MARK: - Single category row

private struct CategoryRow: View {
    let category: CategoryProgress
    let animatedFill: Double
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DS.Space.md) {
                // Emoji
                Text(category.emoji)
                    .font(.system(size: 16))
                    .frame(width: 24)

                // Label + bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.name.uppercased())
                            .font(DS.Font.label(9))
                            .foregroundStyle(category.isLogged
                                             ? DS.Color.ink
                                             : DS.Color.inkSecondary)
                            .tracking(3)

                        Spacer()

                        Text(category.status)
                            .font(DS.Font.data(11))
                            .foregroundStyle(category.isLogged
                                             ? DS.Color.accent
                                             : DS.Color.inkSecondary)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: DS.Radius.pill)
                                .fill(DS.Color.trackBg)
                                .frame(height: DS.RoastCard.barHeight)

                            RoundedRectangle(cornerRadius: DS.Radius.pill)
                                .fill(barColor)
                                .frame(
                                    width: geo.size.width * max(0, min(1, animatedFill)),
                                    height: DS.RoastCard.barHeight
                                )
                        }
                    }
                    .frame(height: DS.RoastCard.barHeight)
                }
            }
            .padding(.vertical, DS.Space.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var barColor: Color {
        if !category.isLogged { return DS.Color.trackBg }
        return animatedFill < 0.5 ? DS.Color.danger : DS.Color.accent
    }
}

// MARK: - Builder from DayLog

extension TodayProgressView {
    /// Builds CategoryProgress array from current manual log state.
    /// Partial scores — full scores computed at midnight by ScoringService.
    static func progress(from log: DayLog?, score: DayScore?) -> [CategoryProgress] {
        [
            sleepProgress(score: score),
            physicalProgress(log: log),
            screenProgress(score: score),
            schoolProgress(log: log),
            homeworkProgress(log: log),
        ]
    }

    private static func sleepProgress(score: DayScore?) -> CategoryProgress {
        if let s = score {
            return CategoryProgress(
                name: "Sleep", emoji: "😴",
                fill: Double(s.sleepScore) / 100,
                isLogged: true,
                status: "\(s.sleepScore)/100"
            )
        }
        return CategoryProgress(
            name: "Sleep", emoji: "😴",
            fill: 0, isLogged: false,
            status: "Auto-pulled at midnight"
        )
    }

    private static func physicalProgress(log: DayLog?) -> CategoryProgress {
        guard let log = log else {
            return CategoryProgress(name: "Physical", emoji: "💪",
                                    fill: 0, isLogged: false, status: "No workout logged")
        }
        let mins = Int(log.totalWorkoutDuration / 60)
        let fill = min(1.0, Double(mins) / 45.0)
        return CategoryProgress(
            name: "Physical", emoji: "💪",
            fill: fill,
            isLogged: !log.workouts.isEmpty,
            status: log.workouts.isEmpty ? "Log workout →" : "\(mins) min"
        )
    }

    private static func screenProgress(score: DayScore?) -> CategoryProgress {
        if let s = score {
            return CategoryProgress(
                name: "Screen", emoji: "📱",
                fill: Double(s.screenScore) / 100,
                isLogged: true,
                status: "\(s.screenScore)/100"
            )
        }
        return CategoryProgress(
            name: "Screen", emoji: "📱",
            fill: 0, isLogged: false,
            status: "Auto-pulled at midnight"
        )
    }

    private static func schoolProgress(log: DayLog?) -> CategoryProgress {
        guard let log = log else {
            return CategoryProgress(name: "School", emoji: "📚",
                                    fill: 0, isLogged: false, status: "Not logged")
        }
        if !log.schoolAttended {
            return CategoryProgress(name: "School", emoji: "📚",
                                    fill: 0, isLogged: true, status: "Not attended")
        }
        let productive = log.productiveFreePeriods
        let wasted = log.wastedFreePeriods
        let total = productive + wasted
        let fill = total == 0 ? 0.7 : min(1.0, 0.7 + Double(productive) * 0.1)
        return CategoryProgress(
            name: "School", emoji: "📚",
            fill: fill, isLogged: true,
            status: total == 0 ? "Attended" : "\(productive)P \(wasted)W"
        )
    }

    private static func homeworkProgress(log: DayLog?) -> CategoryProgress {
        guard let log = log else {
            return CategoryProgress(name: "Homework", emoji: "✏️",
                                    fill: 0, isLogged: false, status: "Not logged")
        }
        guard log.homeworkCompleted else {
            let isLogged = log.homeworkDelay != nil // delay logged = they said they haven't done it yet
            return CategoryProgress(name: "Homework", emoji: "✏️",
                                    fill: isLogged ? 0.1 : 0,
                                    isLogged: isLogged,
                                    status: "Not done ❌")
        }
        let delay = log.homeworkDelay ?? 0
        let fill = delay < 1800 ? 1.0 : delay < 3600 ? 0.8 : delay < 7200 ? 0.6 : 0.3
        let delayStr = delay < 60 ? "Right away" : "\(Int(delay / 60))min delay"
        return CategoryProgress(
            name: "Homework", emoji: "✏️",
            fill: fill, isLogged: true,
            status: "Done · \(delayStr)"
        )
    }
}

#Preview {
    TodayProgressView(categories: TodayProgressView.progress(from: nil, score: nil))
        .padding()
        .background(DS.Color.bg)
}
