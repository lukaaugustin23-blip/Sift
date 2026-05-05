import SwiftUI
import SwiftData

struct RoastView: View {
    let score:   DayScore
    let profile: UserProfile
    let streak:  Int

    @Environment(\.dismiss) private var dismiss

    @State private var cardOffset:  CGFloat = 80
    @State private var cardOpacity: Double  = 0
    @State private var cardScale:   CGFloat = 0.93
    @State private var showShare    = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                DS.Color.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Space.lg) {

                        // ── Top bar ────────────────────────────────────────
                        topBar
                            .padding(.top, geo.safeAreaInsets.top + DS.Space.sm)

                        // ── Card ───────────────────────────────────────────
                        RoastCard(score: score, profile: profile, streak: streak)
                            .offset(y: cardOffset)
                            .opacity(cardOpacity)
                            .scaleEffect(cardScale)
                            .padding(.horizontal, (geo.size.width - RoastCard.cardWidth) / 2)

                        // ── Tip ────────────────────────────────────────────
                        if !score.tip.isEmpty {
                            tipCard
                                .opacity(cardOpacity)
                        }

                        // ── Actions ────────────────────────────────────────
                        actionButtons
                            .opacity(cardOpacity)

                        Spacer(minLength: geo.safeAreaInsets.bottom + DS.Space.xl)
                    }
                    .padding(.horizontal, DS.Space.lg)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.ink)
                    .frame(width: 36, height: 36)
                    .background(DS.Color.surface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            }

            Spacer()

            Text("TODAY'S ROAST")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    // MARK: - Tip

    private var tipCard: some View {
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
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: DS.Space.sm) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showShare = true
            } label: {
                HStack(spacing: DS.Space.sm) {
                    Image(systemName: "square.and.arrow.up")
                    Text("SHARE CARD →")
                }
                .primaryButtonStyle()
            }
        }
    }

    // MARK: - Entrance animation

    private func animateEntrance() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
            cardOffset  = 0
            cardOpacity = 1
            cardScale   = 1
        }
    }
}

#Preview {
    let s = DayScore(overall: 72, productiveTime: 7200, wastedTime: 5400,
                     roast: "You spent more time on TikTok than on anything productive.",
                     tip: "Delete TikTok from your home screen tonight.")
    s.callouts = [Callout(type: .positive, emoji: "✅", text: "2h productive")]
    return RoastView(score: s, profile: UserProfile(name: "Luka"), streak: 7)
        .modelContainer(for: [DayScore.self], inMemory: true)
}
