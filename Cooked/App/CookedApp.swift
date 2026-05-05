import SwiftUI
import SwiftData

@main
struct CookedApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, DayLog.self, DayScore.self])
    }
}

// MARK: - RootView — routes between onboarding and main app

struct RootView: View {
    @Query private var profiles: [UserProfile]

    private var onboardingComplete: Bool {
        profiles.first?.onboardingCompleted == true
    }

    var body: some View {
        Group {
            if onboardingComplete {
                // Placeholder — replaced in Step 5 (Dashboard)
                ZStack {
                    DS.Color.bg.ignoresSafeArea()
                    VStack(spacing: DS.Space.md) {
                        Text("COOKED")
                            .font(DS.Font.hero())
                            .foregroundStyle(DS.Color.ink)
                        Text("Dashboard coming next.")
                            .font(DS.Font.label())
                            .foregroundStyle(DS.Color.inkSecondary)
                            .labelStyle()
                    }
                }
            } else {
                OnboardingContainerView {
                    // SwiftData @Query auto-refreshes — no manual state needed
                }
            }
        }
        .animation(DS.Animation.cardEntrance, value: onboardingComplete)
    }
}
