import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void

    @State private var logoVisible   = false
    @State private var taglineVisible = false
    @State private var buttonVisible  = false

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: DS.Space.sm) {
                    Text("COOKED")
                        .font(DS.Font.display(72))
                        .foregroundStyle(DS.Color.ink)
                        .opacity(logoVisible ? 1 : 0)
                        .offset(y: logoVisible ? 0 : 24)

                    Text("The app that tells you the truth.")
                        .font(DS.Font.body(16))
                        .foregroundStyle(DS.Color.inkSecondary)
                        .opacity(taglineVisible ? 1 : 0)
                        .offset(y: taglineVisible ? 0 : 12)
                }

                Spacer()

                // Flame graphic (emoji stand-in for v1)
                Text("🔥")
                    .font(.system(size: 64))
                    .opacity(logoVisible ? 1 : 0)
                    .padding(.bottom, DS.Space.xxl)

                Spacer()

                // Start button
                Button(action: onStart) {
                    Text("GET STARTED")
                        .font(DS.Font.label(11))
                        .foregroundStyle(DS.Color.darkText)
                        .tracking(3)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.lg)
                        .background(DS.Color.dark)
                        .clipShape(Capsule())
                }
                .opacity(buttonVisible ? 1 : 0)
                .offset(y: buttonVisible ? 0 : 16)
                .padding(.horizontal, DS.Space.lg)
                .padding(.bottom, DS.Space.xxl)
            }
        }
        .onAppear {
            withAnimation(DS.Animation.cardEntrance) {
                logoVisible = true
            }
            withAnimation(DS.Animation.cardEntrance.delay(0.15)) {
                taglineVisible = true
            }
            withAnimation(DS.Animation.cardEntrance.delay(0.35)) {
                buttonVisible = true
            }
        }
    }
}

#Preview {
    WelcomeView(onStart: {})
}
