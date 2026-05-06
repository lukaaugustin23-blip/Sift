import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background
            DS.Color.bg.ignoresSafeArea()

            // Radial fire glow top-center
            RadialGradient(
                colors: [DS.Color.fireStart.opacity(0.08), .clear],
                center: .init(x: 0.5, y: 0.18),
                startRadius: 0,
                endRadius: 260
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo — "cook" white + "ed." fire gradient, never wraps
                logoText
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                Spacer().frame(height: DS.Space.lg)

                // Tagline
                Text("the app that tells you the truth.")
                    .font(DS.Font.body(16))
                    .foregroundStyle(DS.Color.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                Spacer().frame(height: DS.Space.xl)

                // Fire emoji
                Text("🔥")
                    .font(.system(size: 52))
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                // CTA
                Button(action: onContinue) {
                    Text("Get Started →")
                        .fireButtonStyle()
                }
                .shadow(color: DS.Color.fireStart.opacity(0.35), radius: 20, x: 0, y: 8)
                .padding(.horizontal, DS.Space.lg)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                Spacer().frame(height: DS.Space.xxl)
            }
        }
        .onAppear {
            withAnimation(DS.Anim.spring.delay(0.05)) { appeared = true }
        }
    }

    private var logoText: some View {
        // "cook" in white + "ed." with fire gradient — single line, never wraps
        HStack(spacing: 0) {
            Text("cook")
                .font(DS.Font.display(56))
                .foregroundStyle(DS.Color.text1)

            Text("ed.")
                .font(DS.Font.display(56))
                .gradientText(DS.Gradient.fire)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
