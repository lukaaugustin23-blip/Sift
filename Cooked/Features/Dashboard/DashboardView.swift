import SwiftUI
import SwiftData

struct DashboardView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \DayLog.date, order: .reverse)   private var recentLogs:    [DayLog]
    @Query(sort: \DayScore.date, order: .reverse) private var recentScores:  [DayScore]

    // MARK: Sheet states
    @State private var showQuickLog      = false
    @State private var showWorkoutLog    = false
    @State private var showHomeworkLog   = false
    @State private var showBedtimeCheckIn = false

    // MARK: Processing
    @State private var isProcessing     = false
    @State private var processingError: String? = nil
    @State private var showRoast        = false

    // MARK: Derived data
    private var profile:    UserProfile? { profiles.first }
    private var todayLog:   DayLog?      { recentLogs.first.flatMap  { Calendar.current.isDateInToday($0.date) ? $0 : nil } }
    private var todayScore: DayScore?    { recentScores.first.flatMap { Calendar.current.isDateInToday($0.date) ? $0 : nil } }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Still up"
        }
    }

    private var roastButtonLabel: String {
        if isProcessing                            { return "Processing..." }
        if RateLimitService.shared.hasCalledToday  { return RateLimitService.shared.nextAvailableLabel }
        if todayScore != nil                       { return "VIEW TODAY'S ROAST →" }
        return "GET ROASTED →"
    }

    private var roastButtonEnabled: Bool {
        !isProcessing && !RateLimitService.shared.hasCalledToday
    }

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Space.xl) {

                    // Greeting
                    greetingHeader

                    // Score card
                    scoreCard

                    // 5 category bars
                    categorySection

                    // Error display
                    if let err = processingError {
                        Text(err)
                            .font(DS.Font.body(13))
                            .foregroundStyle(DS.Color.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.top, DS.Space.xxl)
            }

            // Bottom quick-log bar pinned
            VStack {
                Spacer()
                quickLogBar
            }
        }
        .onAppear { ensureTodayLog() }
        .sheet(isPresented: $showQuickLog) {
            if let log = todayLog {
                QuickLogView(log: log)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.bg)
                    .presentationCornerRadius(DS.Radius.card)
            }
        }
        .sheet(isPresented: $showWorkoutLog) {
            if let log = todayLog {
                WorkoutLogView(log: log)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.bg)
                    .presentationCornerRadius(DS.Radius.card)
            }
        }
        .sheet(isPresented: $showHomeworkLog) {
            if let log = todayLog {
                HomeworkLogView(log: log)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.bg)
                    .presentationCornerRadius(DS.Radius.card)
            }
        }
        .sheet(isPresented: $showBedtimeCheckIn) {
            if let log = todayLog {
                BedtimeCheckInView(log: log)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.bg)
                    .presentationCornerRadius(DS.Radius.card)
            }
        }
    }

    // MARK: - Greeting header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(greeting.uppercased() + ",")
                .font(DS.Font.label(10))
                .foregroundStyle(DS.Color.inkSecondary)
                .tracking(3)

            Text(profile?.name.isEmpty == false ? profile!.name : "You")
                .font(DS.Font.hero(44))
                .foregroundStyle(DS.Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Score card

    private var scoreCard: some View {
        VStack(spacing: DS.Space.sm) {
            if let score = todayScore {
                // Score computed — show it
                HStack(alignment: .firstTextBaseline, spacing: DS.Space.sm) {
                    Text("\(score.overall)")
                        .font(DS.Font.display(72))
                        .foregroundStyle(DS.Color.ink)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(score.grade)
                            .font(DS.Font.heading(28))
                            .foregroundStyle(DS.Color.accent)
                        Text("TODAY")
                            .labelStyle()
                            .foregroundStyle(DS.Color.inkSecondary)
                    }
                }

                // Get roasted button
                Button { Task { await processAndRoast() } } label: {
                    roastButtonContent
                }
                .disabled(!roastButtonEnabled)

            } else {
                // Day in progress
                VStack(spacing: DS.Space.sm) {
                    HStack(spacing: DS.Space.sm) {
                        Text("—")
                            .font(DS.Font.display(72))
                            .foregroundStyle(DS.Color.inkSecondary)

                        VStack(alignment: .leading) {
                            Text("DAY IN")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)
                            Text("PROGRESS")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)
                        }
                    }

                    Button { Task { await processAndRoast() } } label: {
                        roastButtonContent
                    }
                    .disabled(!roastButtonEnabled)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Space.lg)
        .background(DS.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    @ViewBuilder
    private var roastButtonContent: some View {
        HStack {
            if isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(DS.Color.darkText)
                    .scaleEffect(0.8)
            }
            Text(roastButtonLabel.uppercased())
                .font(DS.Font.label(10))
                .foregroundStyle(roastButtonEnabled ? DS.Color.darkText : DS.Color.inkSecondary)
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.md)
        .background(roastButtonEnabled ? DS.Color.dark : DS.Color.bgSecondary)
        .clipShape(Capsule())
        .animation(DS.Animation.buttonPress, value: roastButtonEnabled)
    }

    // MARK: - Category bars

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("TODAY'S BREAKDOWN")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            TodayProgressView(
                categories: TodayProgressView.progress(from: todayLog, score: todayScore),
                onTap: { cat in handleCategoryTap(cat) }
            )
            .padding(DS.Space.md)
            .background(DS.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
        }
    }

    // MARK: - Quick log bar

    private var quickLogBar: some View {
        HStack(spacing: DS.Space.sm) {
            QuickLogButton(label: "+ Workout", emoji: "💪") {
                haptic()
                showWorkoutLog = true
            }
            QuickLogButton(label: "+ Log Day", emoji: "📋") {
                haptic()
                showQuickLog = true
            }
            QuickLogButton(label: "Homework", emoji: "✏️") {
                haptic()
                showHomeworkLog = true
            }
            QuickLogButton(label: "Bedtime", emoji: "🌙") {
                haptic()
                showBedtimeCheckIn = true
            }
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
        .background(
            DS.Color.bg
                .shadow(color: DS.Color.ink.opacity(0.06), radius: 16, y: -8)
        )
    }

    // MARK: - Category tap routing

    private func handleCategoryTap(_ cat: CategoryProgress) {
        haptic(.light)
        switch cat.name {
        case "Physical":  showWorkoutLog     = true
        case "Homework":  showHomeworkLog     = true
        case "Sleep":     showBedtimeCheckIn  = true
        default:          showQuickLog        = true
        }
    }

    // MARK: - Ensure today's log exists

    private func ensureTodayLog() {
        guard todayLog == nil else { return }
        let log = DayLog(date: Calendar.current.startOfDay(for: Date()))
        modelContext.insert(log)
        try? modelContext.save()
    }

    // MARK: - Process day + generate roast

    private func processAndRoast() async {
        guard let log = todayLog, let profile = profile else { return }
        guard roastButtonEnabled else { return }

        await MainActor.run {
            isProcessing = true
            processingError = nil
        }

        defer { Task { @MainActor in isProcessing = false } }

        // 1. Fetch health data
        let health = await HealthKitService.shared.fetchAllHealthData(for: log.date)
        let screen = await ScreenTimeService.shared.fetchScreenTime(for: log.date, profile: profile)

        // 2. Score
        let score = ScoringService.shared.calculateScore(
            health: health, screen: screen, log: log, profile: profile
        )
        await MainActor.run { modelContext.insert(score) }

        // 3. Roast via Groq (if rate limit allows)
        if RateLimitService.shared.canCallClaudeToday() {
            do {
                let result = try await ClaudeService.shared.generateRoast(
                    score: score, log: log, profile: profile
                )
                await MainActor.run {
                    score.roast = result.roast
                    score.tip   = result.tip
                    RateLimitService.shared.markClaudeCalled()
                }
            } catch {
                await MainActor.run {
                    processingError = "Roast failed: \(error.localizedDescription)"
                }
            }
        }

        await MainActor.run {
            try? modelContext.save()
            showRoast = true
        }
    }

    // MARK: - Haptics

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Quick Log Button

private struct QuickLogButton: View {
    let label: String
    let emoji: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 20))
                Text(label.uppercased())
                    .font(DS.Font.label(7))
                    .foregroundStyle(DS.Color.inkSecondary)
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.sm)
            .background(DS.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserProfile.self, DayLog.self, DayScore.self], inMemory: true)
}
