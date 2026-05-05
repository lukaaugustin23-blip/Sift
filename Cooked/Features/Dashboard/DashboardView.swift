import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt)          private var profiles:     [UserProfile]
    @Query(sort: \DayScore.date, order: .reverse) private var recentScores: [DayScore]

    @State private var screenData:    ScreenTimeData? = nil
    @State private var isProcessing   = false
    @State private var processingErr: String? = nil
    @State private var activeScore:   DayScore? = nil
    @State private var appeared       = false

    private var profile:    UserProfile? { profiles.first }
    private var todayScore: DayScore?    {
        recentScores.first.flatMap {
            Calendar.current.isDateInToday($0.date) ? $0 : nil
        }
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

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DS.Color.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Space.lg) {

                        // ── Top spacer (safe area) ─────────────────────────
                        Color.clear.frame(height: geo.safeAreaInsets.top + DS.Space.md)

                        // ── Greeting ───────────────────────────────────────
                        greetingSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        // ── Score ring ─────────────────────────────────────
                        scoreCard(geo: geo)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)

                        // ── Stats ──────────────────────────────────────────
                        if let data = screenData ?? todayScoreAsData {
                            statsRow(data: data)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 32)
                        }

                        // ── Error ──────────────────────────────────────────
                        if let err = processingErr {
                            Text(err)
                                .font(DS.Font.body(13))
                                .foregroundStyle(DS.Color.danger)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // ── Streak ─────────────────────────────────────────
                        streakView
                            .opacity(appeared ? 1 : 0)

                        Spacer(minLength: DS.Space.xxl)
                    }
                    .padding(.horizontal, DS.Space.lg)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .onAppear {
            withAnimation(DS.Animation.cardEntrance) { appeared = true }
            refreshScreenData()
        }
        .fullScreenCover(item: $activeScore) { score in
            if let profile = profile {
                RoastView(score: score, profile: profile, streak: streak)
            }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(greeting.uppercased())
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)
            Text(profile?.name.isEmpty == false ? profile!.name : "You")
                .font(DS.Font.hero(44))
                .foregroundStyle(DS.Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Score card

    @ViewBuilder
    private func scoreCard(geo: GeometryProxy) -> some View {
        let ringSize = min(geo.size.width * 0.52, 200)
        let fill     = todayScore.map { Double($0.overall) / 100 } ?? (screenData?.productiveRatio)

        VStack(spacing: DS.Space.lg) {
            // Ring
            ZStack {
                ScoreRing(fill: fill ?? 0, size: ringSize, hasData: fill != nil)

                VStack(spacing: DS.Space.xs) {
                    if let score = todayScore {
                        Text("\(score.overall)")
                            .font(DS.Font.display(ringSize * 0.34))
                            .foregroundStyle(DS.Color.ink)
                            .contentTransition(.numericText())
                        Text(score.gradeValue.label)
                            .labelStyle()
                            .foregroundStyle(score.gradeValue.color)
                    } else if let data = screenData, data.totalTime > 0 {
                        Text("\(Int(data.productiveRatio * 100))")
                            .font(DS.Font.display(ringSize * 0.34))
                            .foregroundStyle(DS.Color.ink)
                        Text("PRODUCTIVE")
                            .labelStyle()
                            .foregroundStyle(DS.Color.inkSecondary)
                    } else {
                        Text("—")
                            .font(DS.Font.display(ringSize * 0.34))
                            .foregroundStyle(DS.Color.inkSecondary)
                        Text("NO DATA YET")
                            .labelStyle()
                            .foregroundStyle(DS.Color.inkSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Space.md)

            // Roast button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await processAndRoast() }
            } label: {
                HStack(spacing: DS.Space.sm) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(DS.Color.darkText)
                            .scaleEffect(0.75)
                    }
                    Text(roastButtonLabel)
                        .font(DS.Font.label(10))
                        .foregroundStyle(DS.Color.darkText)
                        .tracking(3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.md + 4)
                .background(roastButtonEnabled ? DS.Color.ink : DS.Color.bgSecondary)
                .clipShape(Capsule())
            }
            .disabled(!roastButtonEnabled)
            .padding(.horizontal, DS.Space.md)
            .padding(.bottom, DS.Space.md)
        }
        .cardStyle()
    }

    private var roastButtonLabel: String {
        if isProcessing                            { return "ANALYSING..." }
        if RateLimitService.shared.hasCalledToday  { return RateLimitService.shared.nextAvailableLabel.uppercased() }
        if todayScore != nil                       { return "VIEW TODAY'S ROAST →" }
        return "GET ROASTED →"
    }

    private var roastButtonEnabled: Bool {
        !isProcessing && (!RateLimitService.shared.hasCalledToday || todayScore != nil)
    }

    // MARK: - Stats row

    @ViewBuilder
    private func statsRow(data: ScreenTimeData) -> some View {
        HStack(spacing: DS.Space.sm) {
            StatPill(label: "PRODUCTIVE", value: formatTime(data.productiveTime), color: DS.Color.accent)
            StatPill(label: "WASTED",     value: formatTime(data.wastedTime),     color: DS.Color.danger)
            StatPill(label: "TOP APP",    value: data.topApp.isEmpty ? "—" : shortAppName(data.topApp), color: DS.Color.ink)
        }
    }

    // MARK: - Streak

    private var streakView: some View {
        HStack(spacing: DS.Space.sm) {
            Text(streak > 0 ? "🔥" : "💤")
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(streak > 0 ? "\(streak) DAY STREAK" : "START YOUR STREAK")
                    .labelStyle()
                    .foregroundStyle(DS.Color.ink)
                Text(streak > 0 ? "Keep it going tonight." : "Get roasted today to begin.")
                    .font(DS.Font.body(13))
                    .foregroundStyle(DS.Color.inkSecondary)
            }
            Spacer()
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - Helpers

    private var todayScoreAsData: ScreenTimeData? {
        guard let s = todayScore else { return nil }
        return ScreenTimeData(
            productiveTime: s.productiveTime,
            wastedTime: s.wastedTime,
            totalTime: s.totalScreenTime,
            topApp: s.topWastedApp
        )
    }

    private func refreshScreenData() {
        guard let profile = profile else { return }
        Task {
            let data = await ScreenTimeService.shared.fetchScreenTime(for: Date(), profile: profile)
            await MainActor.run { screenData = data }
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t / 3600)
        let m = Int((t.truncatingRemainder(dividingBy: 3600)) / 60)
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private func shortAppName(_ bundleId: String) -> String {
        let map: [String: String] = [
            "com.zhiliaoapp.musically": "TikTok",
            "com.burbn.instagram": "Instagram",
            "com.google.ios.youtube": "YouTube",
            "com.atebits.Tweetie2": "Twitter",
            "com.netflix.Netflix": "Netflix",
            "com.reddit.Reddit": "Reddit",
            "com.hammerandchisel.discord": "Discord",
        ]
        return map[bundleId] ?? bundleId.components(separatedBy: ".").last ?? bundleId
    }

    // MARK: - Process

    private func processAndRoast() async {
        guard let profile = profile else { return }

        if let existing = todayScore {
            activeScore = existing
            return
        }

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
}

// MARK: - Score Ring

private struct ScoreRing: View {
    let fill:    Double
    let size:    CGFloat
    let hasData: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.Color.trackBg, lineWidth: size * 0.07)
                .frame(width: size, height: size)

            if hasData {
                Circle()
                    .trim(from: 0, to: fill)
                    .stroke(
                        fill >= 0.6 ? DS.Color.accent : DS.Color.danger,
                        style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.2, dampingFraction: 0.78), value: fill)
            }
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: DS.Space.xs) {
            Text(label)
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)
            Text(value)
                .font(DS.Font.data(14))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.md)
        .cardStyle()
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserProfile.self, DayScore.self], inMemory: true)
}
