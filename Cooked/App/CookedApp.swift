import SwiftUI
import SwiftData

@main
struct CookedApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, DayScore.self])
    }
}

// MARK: - Root routing

struct RootView: View {
    @Query private var profiles: [UserProfile]
    private var onboardingComplete: Bool { profiles.first?.onboardingCompleted == true }

    var body: some View {
        Group {
            if onboardingComplete {
                DashboardView()
            } else {
                OnboardingContainerView()
            }
        }
        .animation(DS.Anim.spring, value: onboardingComplete)
    }
}
