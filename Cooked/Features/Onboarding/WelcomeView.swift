import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void

    @State private var t0 = false   // "cooked." logo
    @State private var t1 = false   // tagline
    @State private var t2 = false   // emoji
    @State private var t3 = false   // button

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DS.Color.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Logo block ─────────────────────────────────────────
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("cooked.")
                            .font(DS.Font.display(min(geo.size.width * 0.22, 88)))
                            .foregroundStyle(DS.Color.ink)
                            .opacity(t0 ? 1 : 0)
                            .offset(y: t0 ? 0 : 40)

                        Text("The app that tells you\nthe truth.")
                            .font(DS.Font.body(18))
                            .foregroundStyle(DS.Color.inkSecondary)
                            .lineSpacing(4)
                            .opacity(t1 ? 1 : 0)
                            .offset(y: t1 ? 0 : 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, geo.size.height * 0.15)

                    Spacer()

                    // ── Flame ──────────────────────────────────────────────
                    Text("🔥")
                        .font(.system(size: min(geo.size.width * 0.32, 128)))
                        .opacity(t2 ? 1 : 0)
                        .scaleEffect(t2 ? 1 : 0.5)

                    Spacer()

                    // ── CTA ────────────────────────────────────────────────
                    VStack(spacing: DS.Space.md) {
                        Text("DAILY SCORE · AI ROAST · NO MERCY")
                            .font(DS.Font.label(8))
                            .foregroundStyle(DS.Color.inkSecondary)
                            .tracking(3)
                            .multilineTextAlignment(.center)
                            .opacity(t3 ? 1 : 0)

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onStart()
                        } label: {
                            Text("GET STARTED →")
                                .primaryButtonStyle()
                        }
                        .opacity(t3 ? 1 : 0)
                        .offset(y: t3 ? 0 : 24)
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.bottom, geo.safeAreaInsets.bottom + DS.Space.xl)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            let spring = DS.Animation.cardEntrance
            withAnimation(spring)                        { t0 = true }
            withAnimation(spring.delay(0.12))            { t1 = true }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.28)) { t2 = true }
            withAnimation(spring.delay(0.45))            { t3 = true }
        }
    }
}

#Preview { WelcomeView(onStart: {}) }
