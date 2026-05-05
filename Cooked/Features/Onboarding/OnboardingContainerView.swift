import SwiftUI
import SwiftData

private enum OnboardingStep: Int, CaseIterable {
    case welcome = 0, setup = 1, apps = 2
}

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var step:         OnboardingStep = .welcome
    @State private var name:         String         = ""
    @State private var goals:        [String]       = ["", "", ""]
    @State private var roastStyle:   RoastStyle     = .savage
    @State private var uncensored:   Bool           = false
    @State private var productiveIds:[String]       = []
    @State private var wastedIds:    [String]       = []

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            if step != .welcome {
                progressBar.padding(.top, DS.Space.xxl).zIndex(1)
            }

            Group {
                switch step {
                case .welcome:
                    WelcomeView(onStart: { advance() })
                        .transition(slide)

                case .setup:
                    SetupView(
                        name: $name, goals: $goals,
                        roastStyle: $roastStyle, uncensored: $uncensored,
                        onContinue: { advance() }
                    )
                    .padding(.top, 48)
                    .transition(slide)

                case .apps:
                    AppCategorizationView(
                        productiveIds: $productiveIds,
                        wastedIds: $wastedIds,
                        onContinue: { completeOnboarding() }
                    )
                    .padding(.top, 48)
                    .transition(slide)
                }
            }
            .animation(DS.Animation.cardEntrance, value: step)
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        let total   = Double(OnboardingStep.allCases.count - 1)
        let current = Double(max(0, step.rawValue - 1))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.Color.bgSecondary).frame(height: 3)
                Capsule().fill(DS.Color.ink)
                    .frame(width: geo.size.width * (current / total), height: 3)
                    .animation(DS.Animation.standard, value: step)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, DS.Space.lg)
    }

    private var slide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        )
    }

    private func advance() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch step {
        case .welcome: step = .setup
        case .setup:   step = .apps
        case .apps:    completeOnboarding()
        }
    }

    private func completeOnboarding() {
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            goals: goals,
            roastStyle: roastStyle,
            uncensoredMode: uncensored,
            productiveAppBundleIds: productiveIds,
            wastedAppBundleIds: wastedIds,
            onboardingCompleted: true
        )
        modelContext.insert(profile)
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserProfile.self, DayScore.self], inMemory: true)
}
