import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var step      = 0
    @State private var name      = ""
    @State private var goals     = ["", "", ""]
    @State private var roastStyle: RoastStyle = .savage
    @State private var uncensored = false

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            // Slide transition between steps
            if step == 0 {
                WelcomeView(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                SetupView(
                    name:        $name,
                    goals:       $goals,
                    roastStyle:  $roastStyle,
                    uncensored:  $uncensored,
                    onDone:      completeOnboarding
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(DS.Anim.slide, value: step)
    }

    private func nextStep() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        step = 1
    }

    private func completeOnboarding() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let profile = UserProfile(name: name.trimmingCharacters(in: .whitespaces))
        profile.goals        = goals.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        profile.roastStyle   = roastStyle
        profile.uncensoredMode = uncensored
        profile.onboardingCompleted = true
        modelContext.insert(profile)
        try? modelContext.save()
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserProfile.self, DayScore.self], inMemory: true)
}
