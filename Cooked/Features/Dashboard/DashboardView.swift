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
    private var todayScore: DayScore? {
        recentScores.first.flatMap {
            Calendar.current.isDateInToday($0.date) ? $0 : nil
        }
    }
    private var displayScore: Int {
        if let s = todayScore { return s.overall }
        if let d = screenData, d.totalTime > 0 { return Int(d.productiveRatio * 100) }
        return 0
    }
    private var hasScore: Bool {
        todayScore != nil || (screenData?.totalTime ?? 0) > 0
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
        ZStack {
            Color(hex: "F5F1E8").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Greeting + name ───────────────────────────────
                    headerSection
                        .padding(.horizontal, DS.Space.lg)
                        .padding(.top, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Spacer().frame(height: DS.Space.xl)

                    // ── Score block ────────────────────────────────────
                    scoreBlock
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 28)

                    Spacer().frame(height: DS.Space.xl)

                    // ── Action button ──────────────────────────────────
                    actionButton
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 32)

                    Spacer().frame(height: DS.Space.lg)

                    // ── Stats row ──────────────────────────────────────
                    statsRow
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 36)

                    Spacer().frame(height: DS.Space.md)

                    // ── Streak ─────────────────────────────────────────
                    streakRow
                        .padding(.horizontal, DS.Space.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 40)

                    // ── Error ──────────────────────────────────────────
                    if let err = processingErr {
                        Text(err)
                            .font(DS.Font.body(13))
                            .foregroundStyle(DS.Color.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Space.lg)
                            .padding(.top, DS.Space.md)
                    }

                    Spacer().frame(height: DS.Space.xxl)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) { appeared = true }
            refreshScreenData()
        }
        .fullScreenCover(item: $activeScore) { score in
            if let profile = profile {
                RoastView(score: score, profile: profile, streak: streak)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(greeting.uppercased())
                .font(.spaceMono(9))
                .foregroundStyle(DS.Color.inkSecondary)
                .tracking(4)

            Text(profile?.name.isEmpty == false ? profile!.name : "You")
                .font(DS.Font.hero(40))
                .foregroundStyle(DS.Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Score block

    private var scoreBlock: some View {
        HStack(alignment: .bottom, spacing: DS.Space.lg) {
            // Giant score number
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                if hasScore {
                    HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
                        Text("\(displayScore)")
                            .font(DS.Font.display(96))
                            .foregroundStyle(DS.Color.ink)
                            .contentTransition(.numericText())

                        Text("%")
                            .font(DS.Font.heading(28))
                            .foregroundStyle(DS.Color.inkSecondary)
                            .padding(.bottom, 14)
                    }
                } else {
                    Text("—")
                        .font(DS.Font.display(96))
                        .foregroundStyle(DS.Color.inkSecondary)
                }

                Text(hasScore ? "PRODUCTIVE TODAY" : "NO DATA YET")
                    .font(.spaceMono(9))
                    .foregroundStyle(DS.Color.inkSecondary)
                    .tracking(3)
            }

            Spacer()

            // Grade badge
            if let score = todayScore {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(DS.Color.ink)
                        .frame(width: 60, height: 60)
                    Text(score.grade)
                        .font(DS.Font.display(32))
                        .foregroundStyle(DS.Color.accent)
                }
                .shadow(color: DS.Color.ink.opacity(0.25), radius: 16, x: 0, y: 6)
            } else if hasScore {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(DS.Color.ink)
                        .frame(width: 60, height: 60)
                    Text(Grade.from(displayScore).rawValue)
                        .font(DS.Font.display(32))
                        .foregroundStyle(DS.Color.accent)
                }
                .shadow(color: DS.Color.ink.opacity(0.25), radius: 16, x: 0, y: 6)
            }
        }
    }

    // MARK: - Action button

    private var actionButton: some View {
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
                    .font(.spaceMono(10))
                    .foregroundStyle(
                        roastButtonEnabled ? DS.Color.darkText : DS.Color.inkSecondary
                    )
                    .tracking(3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.md + 4)
            .background(
                roastButtonEnabled
                    ? DS.Color.ink
                    : DS.Color.ink.opacity(0.06)
            )
            .clipShape(Capsule())
            .shadow(
                color: roastButtonEnabled ? DS.Color.ink.opacity(0.18) : .clear,
                radius: 16, x: 0, y: 6
            )
        }
        .disabled(!roastButtonEnabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: roastButtonEnabled)
    }

    private var roastButtonLabel: String {
        if isProcessing                            { return "ANALYSING..." }
        if RateLimitService.shared.hasCalledToday  {
            return RateLimitService.shared.nextAvailableLabel.uppercased()
        }
        if todayScore != nil { return "VIEW TODAY'S ROAST →" }
        return "GET ROASTED →"
    }

    private var roastButtonEnabled: Bool {
        !isProcessing && (!RateLimitService.shared.hasCalledToday || todayScore != nil)
    }

    // MARK: - Stats row

    private var statsRow: some View {
        let data: ScreenTimeData? = todayScore.map {
            ScreenTimeData(
                productiveTime: $0.productiveTime,
                wastedTime: $0.wastedTime,
                totalTime: $0.totalScreenTime,
                topApp: $0.topWastedApp
            )
        } ?? screenData

        return HStack(spacing: DS.Space.sm) {
            DarkStatCard(
                label: "PRODUCTIVE",
                value: data.map { formatTime($0.productiveTime) } ?? "—",
                color: DS.Color.accent
            )
            DarkStatCard(
                label: "WASTED",
                value: data.map { formatTime($0.wastedTime) } ?? "—",
                color: DS.Color.danger
            )
            DarkStatCard(
                label: "TOP APP",
                value: data.flatMap { $0.topApp.isEmpty ? nil : shortApp($0.topApp) } ?? "—",
                color: DS.Color.darkText
            )
        }
    }

    // MARK: - Streak row

    private var streakRow: some View {
        HStack(spacing: DS.Space.md) {
            Text(streak > 0 ? "🔥" : "💤")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 3) {
                Text(streak > 0 ? "\(streak) DAY STREAK" : "NO STREAK YET")
                    .font(.spaceMono(9))
                    .foregroundStyle(DS.Color.ink)
                    .tracking(3)

                Text(streak > 0 ? "Keep it going." : "Get roasted to start.")
                    .font(DS.Font.body(13))
                    .foregroundStyle(DS.Color.inkSecondary)
            }

            Spacer()

            if streak > 0 {
                Text("\(streak)")
                    .font(DS.Font.data(18))
                    .foregroundStyle(DS.Color.ink)
            }
        }
        .padding(DS.Space.md)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
    }

    // MARK: - Helpers

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
        return m == 0 ? "0m" : "\(m)m"
    }

    private func shortApp(_ bundleId: String) -> String {
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
        return map[bundleId] ?? (bundleId.components(separatedBy: ".").last?.capitalized ?? bundleId)
    }

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
}

// MARK: - Dark Stat Card

private struct DarkStatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(label)
                .font(.spaceMono(7))
                .foregroundStyle(Color.white.opacity(0.45))
                .tracking(2)

            Text(value)
                .font(DS.Font.data(15))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.ink)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: DS.Color.ink.opacity(0.18), radius: 16, x: 0, y: 6)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserProfile.self, DayScore.self], inMemory: true)
}
