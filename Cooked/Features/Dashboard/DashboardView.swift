import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt)          private var profiles:     [UserProfile]
    @Query(sort: \DayScore.date, order: .reverse) private var recentScores: [DayScore]

    // Demo: overlay shown on open; tapping yesterday card re-opens it
    @State private var showRoastOverlay = true
    @State private var appeared         = false

    // Use fake data for demo
    private var demoScore:   DayScore    { FakeData.score }
    private var demoProfile: UserProfile { FakeData.profile }
    private var demoStreak:  Int         { FakeData.streak }
    private var displayName: String      {
        let real = profiles.first?.name
        return (real?.isEmpty == false) ? real! : "Luka"
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<21: return "Good evening,"
        default:      return "Still up,"
        }
    }

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()
            ambientGlows

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    Spacer().frame(height: DS.Space.sm)

                    // Greeting
                    headerSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)

                    // Yesterday summary card
                    yesterdayCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 22)

                    // Get Better section
                    getBetterSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 26)

                    // Remember Why quote
                    rememberWhySection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)

                    // Streak
                    streakSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 34)

                    Spacer().frame(height: DS.Space.xxl)
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // Morning roast overlay
            if showRoastOverlay {
                MorningRoastOverlay(
                    score:    demoScore,
                    profile:  demoProfile,
                    streak:   demoStreak,
                    onDismiss: { showRoastOverlay = false }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(DS.Anim.spring.delay(0.08)) { appeared = true }
        }
    }

    // MARK: - Ambient glows

    private var ambientGlows: some View {
        ZStack {
            RadialGradient(
                colors: [DS.Color.tealStart.opacity(0.07), .clear],
                center: .init(x: 0.1, y: 0.05),
                startRadius: 0, endRadius: 280
            )
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
            Text(displayName)
                .font(DS.Font.display(38))
                .foregroundStyle(DS.Color.text1)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    // MARK: - Yesterday card

    private var yesterdayCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(DS.Anim.spring) { showRoastOverlay = true }
        } label: {
            HStack(spacing: DS.Space.md) {
                // Score pill
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.badge)
                        .fill(DS.Gradient.fire)
                        .frame(width: 52, height: 52)
                    Text(demoScore.grade)
                        .font(DS.Font.display(24))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("YESTERDAY")
                        .font(DS.Font.label(9))
                        .foregroundStyle(DS.Color.text3)
                        .kerning(1.5)
                    HStack(spacing: DS.Space.xs) {
                        Text("\(demoScore.overall)/100")
                            .font(DS.Font.display(18))
                            .gradientText(DS.Gradient.fire)
                        Text("·")
                            .foregroundStyle(DS.Color.text3)
                        Text("Grade \(demoScore.grade)")
                            .font(DS.Font.label(14))
                            .foregroundStyle(DS.Color.text3)
                    }
                    Text("Tap to view your roast →")
                        .font(DS.Font.body(12))
                        .foregroundStyle(DS.Color.text3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Color.text3)
            }
            .padding(DS.Space.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Get Better section

    private var getBetterSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("GET BETTER")
                .font(DS.Font.label(10))
                .gradientText(DS.Gradient.fire)
                .kerning(1.5)

            VStack(spacing: DS.Space.sm) {
                ForEach(Array(FakeData.tips.enumerated()), id: \.offset) { _, tip in
                    tipCard(tip)
                }
            }
        }
    }

    private func tipCard(_ tip: (emoji: String, text: String, good: Bool)) -> some View {
        HStack(alignment: .top, spacing: DS.Space.md) {
            Text(tip.emoji)
                .font(.system(size: 22))
                .frame(width: 36, height: 36)
                .background(
                    tip.good
                        ? DS.Color.tealStart.opacity(0.12)
                        : DS.Color.fireStart.opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.text)
                    .font(DS.Font.body(13.5))
                    .foregroundStyle(DS.Color.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }

            Spacer()

            Rectangle()
                .fill(tip.good ? DS.Color.tealStart : DS.Color.fireStart)
                .frame(width: 2)
                .clipShape(Capsule())
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - Remember Why section

    private var rememberWhySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("REMEMBER WHY")
                .font(DS.Font.label(10))
                .gradientText(DS.Gradient.teal)
                .kerning(1.5)

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                HStack(alignment: .top, spacing: DS.Space.sm) {
                    Rectangle()
                        .fill(DS.Gradient.teal)
                        .frame(width: 2)
                        .clipShape(Capsule())
                    Text(FakeData.quote)
                        .font(DS.Font.bodyItalic(13.5))
                        .foregroundStyle(DS.Color.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("— Your goals")
                    .font(DS.Font.label(10))
                    .foregroundStyle(DS.Color.text3)
                    .kerning(1)
                    .padding(.leading, DS.Space.md)
            }
            .padding(DS.Space.md)
            .cardStyle()
        }
    }

    // MARK: - Streak section

    private var streakSection: some View {
        HStack(spacing: DS.Space.md) {
            Text("🔥")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: DS.Space.xs) {
                    Text("\(demoStreak)")
                        .font(DS.Font.display(20))
                        .gradientText(DS.Gradient.fire)
                    Text("DAY STREAK")
                        .font(DS.Font.label(14))
                        .foregroundStyle(DS.Color.text2)
                }
                Text("Keep it going.")
                    .font(DS.Font.body(12))
                    .foregroundStyle(DS.Color.text3)
            }

            Spacer()

            // 7 dots, first 3 filled
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(i < demoStreak
                              ? AnyShapeStyle(DS.Gradient.fire)
                              : AnyShapeStyle(DS.Color.text3.opacity(0.25)))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(DS.Space.md)
        .cardStyle()
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserProfile.self, DayScore.self], inMemory: true)
}
