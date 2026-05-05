import SwiftUI
import SwiftData

struct RoastView: View {
    let score:   DayScore
    let profile: UserProfile
    let streak:  Int

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DayScore.date, order: .reverse) private var allScores: [DayScore]

    @State private var cardOffset:  CGFloat = 60
    @State private var cardOpacity: Double  = 0
    @State private var cardScale:   CGFloat = 0.95
    @State private var showBreakdown = false
    @State private var showShare     = false

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Space.lg) {
                    // Top bar
                    topBar

                    // The card — animated entrance
                    RoastCard(score: score, profile: profile, streak: streak)
                        .offset(y: cardOffset)
                        .opacity(cardOpacity)
                        .scaleEffect(cardScale)
                        .padding(.horizontal, (UIScreen.main.bounds.width - RoastCard.cardWidth) / 2)

                    // Tip
                    tipSection

                    // Actions
                    actionButtons

                    // Breakdown
                    if showBreakdown {
                        SubScoresView(score: score)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer(minLength: DS.Space.xxl)
                }
                .padding(.top, DS.Space.md)
            }
        }
        .onAppear { animateEntrance() }
        .sheet(isPresented: $showShare) {
            ShareCardView(score: score, profile: profile, streak: streak)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(DS.Color.bg)
                .presentationCornerRadius(DS.Radius.card)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.ink)
                    .frame(width: 36, height: 36)
                    .background(DS.Color.bgSecondary)
                    .clipShape(Circle())
            }

            Spacer()

            Text("TODAY'S ROAST")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            Spacer()

            // Balance button
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Tip section

    private var tipSection: some View {
        Group {
            if !score.tip.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("TIP FOR TOMORROW")
                        .labelStyle()
                        .foregroundStyle(DS.Color.inkSecondary)

                    Text(score.tip)
                        .font(DS.Font.body(15))
                        .foregroundStyle(DS.Color.ink)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Space.md)
                .background(DS.Color.calloutPositiveBg)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
                .padding(.horizontal, DS.Space.lg)
            }
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: DS.Space.sm) {
            // Share
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showShare = true
            } label: {
                Label("SHARE CARD →", systemImage: "square.and.arrow.up")
                    .font(DS.Font.label(10))
                    .foregroundStyle(DS.Color.darkText)
                    .tracking(3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.lg)
                    .background(DS.Color.dark)
                    .clipShape(Capsule())
            }

            // Breakdown toggle
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(DS.Animation.cardEntrance) {
                    showBreakdown.toggle()
                }
            } label: {
                HStack(spacing: DS.Space.xs) {
                    Text(showBreakdown ? "HIDE BREAKDOWN ▲" : "SEE BREAKDOWN ▼")
                        .font(DS.Font.label(10))
                        .foregroundStyle(DS.Color.ink)
                        .tracking(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.md)
                .background(DS.Color.bgSecondary)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Entrance animation

    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
            cardOffset  = 0
            cardOpacity = 1
            cardScale   = 1
        }
    }
}

#Preview {
    let score = DayScore()
    score.overall = 72; score.sleepScore = 80; score.physicalScore = 90
    score.screenScore = 60; score.schoolScore = 70; score.homeworkScore = 55
    score.roast = "You crushed the gym but your screen time was embarrassing. The protein won't offset the TikTok spiral."
    score.tip   = "Put your phone in another room tonight."
    score.callouts = [
        Callout(type: .positive, emoji: "🔥", text: "Gym at 4pm"),
        Callout(type: .negative, emoji: "💀", text: "Doomscrolled in bed"),
    ]
    return RoastView(score: score, profile: UserProfile(name: "Luka"), streak: 7)
        .modelContainer(for: DayScore.self, inMemory: true)
}
