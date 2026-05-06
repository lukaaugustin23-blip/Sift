import SwiftUI

struct RoastView: View {
    let score:   DayScore
    let profile: UserProfile
    let streak:  Int

    @Environment(\.dismiss) private var dismiss
    @State private var cardOffset:  CGFloat = 80
    @State private var cardOpacity: CGFloat = 0
    @State private var cardScale:   CGFloat = 0.94
    @State private var showShare    = false

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            // Ambient glow matching score
            RadialGradient(
                colors: [
                    (score.overall >= 60 ? DS.Color.tealStart : DS.Color.fireStart).opacity(0.08),
                    .clear
                ],
                center: .init(x: 0.5, y: 0.1),
                startRadius: 0, endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(DS.Color.card)
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DS.Color.text2)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.top, DS.Space.sm)
                .padding(.bottom, DS.Space.sm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Space.md) {
                        RoastCard(score: score, profile: profile, streak: streak)
                            .padding(.horizontal, DS.Space.lg)

                        // Share button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showShare = true
                        } label: {
                            HStack(spacing: DS.Space.sm) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Share Card →")
                            }
                            .fireButtonStyle()
                        }
                        .shadow(color: DS.Color.fireStart.opacity(0.35), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, DS.Space.lg)

                        Spacer().frame(height: DS.Space.xxl)
                    }
                }
            }
        }
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .scaleEffect(cardScale)
        .onAppear {
            withAnimation(DS.Anim.spring) {
                cardOffset  = 0
                cardOpacity = 1
                cardScale   = 1
            }
        }
        .sheet(isPresented: $showShare) {
            ShareCardView(score: score, profile: profile, streak: streak)
        }
    }
}

#Preview {
    let s = DayScore(overall: 72, productiveTime: 7200, wastedTime: 5400,
                     roast: "You spent more time watching strangers than touching grass.",
                     tip: "Delete TikTok from your home screen tonight.")
    return RoastView(score: s, profile: UserProfile(name: "Luka"), streak: 5)
}
