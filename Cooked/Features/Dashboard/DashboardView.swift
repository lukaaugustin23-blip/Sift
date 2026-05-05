import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt)          private var profiles:     [UserProfile]
    @Query(sort: \DayScore.date, order: .reverse) private var recentScores: [DayScore]

    @State private var isProcessing  = false
    @State private var processingErr: String? = nil
    @State private var activeScore:  DayScore? = nil
    @State private var appeared      = false

    // MARK: - Computed

    private var profile:    UserProfile? { profiles.first }
    private var todayScore: DayScore? {
        recentScores.first.flatMap {
            Calendar.current.isDateInToday($0.date) ? $0 : nil
        }
    }
    private var hasScore: Bool { todayScore != nil }

    // Mock display values — never show fake screen time data
    private var displayScore: Int    { todayScore?.overall ?? 0 }
    private var displayGrade: String { todayScore?.grade ?? "—" }
    private var scoreGradient: LinearGradient {
        guard hasScore else { return DS.Gradient.fire }
        return displayScore >= 60 ? DS.Gradient.teal : DS.Gradient.fire
    }
    private var borderColor: Color {
        guard hasScore else { return DS.Color.fireStart }
        return displayScore >= 60 ? DS.Color.tealStart : DS.Color.fireStart
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<21: return "Good evening,"
        default:      return "Still up,"
        }
    }

    private var streak: Int {
        var s = 0; let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        for _ in 0..<365 {
            if recentScores.contains(where: { cal.isDate($0.date, inSameDayAs: day) }) {
                s += 1; day = cal.date(byAdding: .day, value: -1, to: day)!
            } else { break }
        }
        return s
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Deep dark background
            DS.Color.bg.ignoresSafeArea()

            // Ambient glows
            ambientGlows

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: DS.Space.lg)

                    // Header
                    headerSection
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Spacer().frame(height: DS.Space.lg)

                    // Score card
                    scoreCard
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 28)

                    Spacer().frame(height: DS.Space.md)

                    // Stats row
                    statsRow
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 32)

                    Spacer().frame(height: DS.Space.md)

                    // Bars card
                    barsCard
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 36)

                    Spacer().frame(height: DS.Space.md)

                    // Streak card
                    streakCard
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 40)

                    Spacer().frame(height: DS.Space.lg)

                    // CTA button
                    ctaButton
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 44)

                    // Error
                    if let err = processingErr {
                        Text(err)
                            .font(DS.Font.body(13))
                            .foregroundStyle(DS.Color.fireStart)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Space.lg)
                            .padding(.top, DS.Space.sm)
                    }

                    Spacer().frame(height: DS.Space.xxl)
                }
            }
        }
        .onAppear {
            withAnimation(DS.Anim.spring.delay(0.05)) { appeared = true }
        }
        .fullScreenCover(item: $activeScore) { score in
            if let profile = profile {
                RoastView(score: score, profile: profile, streak: streak)
            }
        }
    }

    // MARK: - Ambient Glows

    private var ambientGlows: some View {
        ZStack {
            // Teal glow top-left
            RadialGradient(
                colors: [DS.Color.tealStart.opacity(0.07), .clear],
                center: .init(x: 0.1, y: 0.05),
                startRadius: 0, endRadius: 280
            )
            // Fire glow top-right
            RadialGradient(
                colors: [DS.Color.fireStart.opacity(0.07), .clear],
                center: .init(x: 0.9, y: 0.05),
                startRadius: 0, endRadius: 280
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting.uppercased())
                .font(DS.Font.label(10))
                .foregroundStyle(DS.Color.text3)
                .kerning(1.5)

            Text(profile?.name.isEmpty == false ? profile!.name : "You")
                .font(DS.Font.display(38))
                .foregroundStyle(DS.Color.text1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(alignment: .bottom, spacing: 0) {
                // Score number
                Group {
                    if hasScore {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(displayScore)")
                                .font(DS.Font.display(90))
                                .gradientText(scoreGradient)
                                .contentTransition(.numericText())
                            Text("/100")
                                .font(DS.Font.display(20))
                                .foregroundStyle(DS.Color.text3)
                                .padding(.bottom, 12)
                        }
                    } else {
                        // No data yet — intentional empty state
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("—")
                                .font(DS.Font.display(90))
                                .foregroundStyle(DS.Color.text3)
                            Text("NO DATA YET")
                                .font(DS.Font.label(10))
                                .foregroundStyle(DS.Color.text3)
                                .kerning(1.5)
                        }
                    }
                }

                Spacer()

                // Grade badge
                if hasScore {
                    ZStack {
                        RoundedRectangle(cornerRadius: DS.Radius.badge)
                            .fill(scoreGradient)
                            .frame(width: 58, height: 58)
                        Text(displayGrade)
                            .font(DS.Font.display(28))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: borderColor.opacity(0.4), radius: 12, x: 0, y: 4)
                }
            }

            // Status / roast text
            if hasScore, let roast = todayScore?.roast, !roast.isEmpty {
                HStack(spacing: DS.Space.sm) {
                    Rectangle()
                        .fill(borderColor)
                        .frame(width: 2)
                    Text(roast)
                        .font(DS.Font.bodyItalic(13.5))
                        .foregroundStyle(DS.Color.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                // First-time / no-data state
                HStack(spacing: DS.Space.sm) {
                    Rectangle()
                        .fill(DS.Gradient.fire)
                        .frame(width: 2)
                    Text("Your first roast is loading. Check back tomorrow morning.")
                        .font(DS.Font.bodyItalic(13.5))
                        .foregroundStyle(DS.Color.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(DS.Space.lg)
        .cardStyle()
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: DS.Space.sm) {
            statCard(
                label: "PRODUCTIVE",
                value: todayScore.map { formatTime($0.productiveTime) } ?? "0m",
                gradient: DS.Gradient.teal,
                hasData: hasScore
            )
            statCard(
                label: "WASTED",
                value: todayScore.map { formatTime($0.wastedTime) } ?? "0m",
                gradient: DS.Gradient.fire,
                hasData: hasScore
            )
            statCard(
                label: "TOP APP",
                value: todayScore.flatMap { shortApp($0.topWastedApp) } ?? "—",
                gradient: DS.Gradient.fire,
                hasData: hasScore
            )
        }
    }

    private func statCard(label: String, value: String, gradient: LinearGradient, hasData: Bool) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(label)
                .font(DS.Font.label(9))
                .foregroundStyle(DS.Color.text3)
                .kerning(1)
            Text(value)
                .font(DS.Font.display(15))
                .if(hasData) { $0.gradientText(gradient) }
                .if(!hasData) { $0.foregroundStyle(DS.Color.text3) }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - Bars Card

    private var barsCard: some View {
        VStack(spacing: DS.Space.md) {
            barRow(
                label: "Productive",
                value: todayScore.map { formatTime($0.productiveTime) } ?? "0m",
                ratio: hasScore ? CGFloat(todayScore!.productiveTime / max(todayScore!.totalScreenTime, 1)) : 0,
                gradient: DS.Gradient.teal
            )
            Divider().background(DS.Color.cardBorder)
            barRow(
                label: "Wasted",
                value: todayScore.map { formatTime($0.wastedTime) } ?? "0m",
                ratio: hasScore ? CGFloat(todayScore!.wastedTime / max(todayScore!.totalScreenTime, 1)) : 0,
                gradient: DS.Gradient.fire
            )
        }
        .padding(DS.Space.lg)
        .cardStyle()
    }

    private func barRow(label: String, value: String, ratio: CGFloat, gradient: LinearGradient) -> some View {
        VStack(spacing: DS.Space.sm) {
            HStack {
                Text(label)
                    .font(DS.Font.label(12))
                    .foregroundStyle(DS.Color.text2)
                Spacer()
                Text(value)
                    .font(DS.Font.label(12))
                    .foregroundStyle(DS.Color.text2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Color.text3.opacity(0.15)).frame(height: 6)
                    Capsule()
                        .fill(gradient)
                        .frame(width: max(geo.size.width * ratio, ratio > 0 ? 6 : 0), height: 6)
                        .animation(DS.Anim.spring.delay(0.4), value: ratio)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: DS.Space.md) {
            Text(streak > 0 ? "🔥" : "💤")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: DS.Space.xs) {
                    if streak > 0 {
                        Text("\(streak)")
                            .font(DS.Font.display(18))
                            .gradientText(DS.Gradient.fire)
                        Text("DAY STREAK")
                            .font(DS.Font.label(13))
                            .foregroundStyle(DS.Color.text2)
                    } else {
                        Text("NO STREAK YET")
                            .font(DS.Font.label(13))
                            .foregroundStyle(DS.Color.text2)
                    }
                }
                Text(streak > 0 ? "Keep it going." : "Get roasted to start.")
                    .font(DS.Font.body(12))
                    .foregroundStyle(DS.Color.text3)
            }

            Spacer()

            // 7 dots
            if streak > 0 {
                HStack(spacing: 5) {
                    ForEach(0..<7, id: \.self) { i in
                        Circle()
                            .fill(i < min(streak, 7) ? AnyShapeStyle(DS.Gradient.fire) : AnyShapeStyle(DS.Color.text3.opacity(0.3)))
                            .frame(width: 7, height: 7)
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task { await processAndRoast() }
        } label: {
            HStack(spacing: DS.Space.sm) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.75)
                }
                Text(ctaLabel)
                    .fireButtonStyle()
                    .background(.clear)
            }
        }
        .shadow(color: ctaEnabled ? DS.Color.fireStart.opacity(0.35) : .clear, radius: 20, x: 0, y: 8)
        .disabled(!ctaEnabled)
        .animation(DS.Anim.fast, value: ctaEnabled)
    }

    private var ctaLabel: String {
        if isProcessing { return "Analysing..." }
        if !RateLimitService.shared.hasCalledToday { return "Get Roasted →" }
        if todayScore != nil { return "View Today's Roast →" }
        return RateLimitService.shared.nextAvailableLabel.uppercased()
    }

    private var ctaEnabled: Bool {
        !isProcessing && (!RateLimitService.shared.hasCalledToday || todayScore != nil)
    }

    // MARK: - Actions

    private func processAndRoast() async {
        guard let profile = profile else { return }
        if let existing = todayScore { activeScore = existing; return }

        isProcessing = true
        processingErr = nil
        defer { isProcessing = false }

        let screen = await ScreenTimeService.shared.fetchScreenTime(for: Date(), profile: profile)
        let score  = ScoringService.shared.calculateScore(screen: screen, profile: profile)
        modelContext.insert(score)

        if RateLimitService.shared.canCallClaudeToday() {
            do {
                let result = try await ClaudeService.shared.generateRoast(score: score, profile: profile)
                score.roast = result.roast
                score.tip   = result.tip
                RateLimitService.shared.markClaudeCalled()
            } catch {
                processingErr = error.localizedDescription
            }
        }

        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        activeScore = score
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t / 3600)
        let m = Int((t.truncatingRemainder(dividingBy: 3600)) / 60)
        if h > 0 { return "\(h)h \(m)m" }
        return m == 0 ? "0m" : "\(m)m"
    }

    private func shortApp(_ bundleId: String) -> String? {
        guard !bundleId.isEmpty else { return nil }
        let map: [String: String] = [
            "com.zhiliaoapp.musically": "TikTok",
            "com.burbn.instagram": "Instagram",
            "com.google.ios.youtube": "YouTube",
            "com.atebits.Tweetie2": "Twitter",
            "com.netflix.Netflix": "Netflix",
            "com.reddit.Reddit": "Reddit",
            "com.hammerandchisel.discord": "Discord",
            "com.apple.MobileSMS": "Messages",
        ]
        return map[bundleId] ?? bundleId.components(separatedBy: ".").last?.capitalized
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserProfile.self, DayScore.self], inMemory: true)
}
