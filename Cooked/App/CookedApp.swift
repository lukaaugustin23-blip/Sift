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

    @State private var showRoastOverlay = true

    var body: some View {
        Group {
            if true { // DEMO
                MainTabView(showRoastOverlay: $showRoastOverlay)
            } else {
                OnboardingContainerView()
            }
        }
        .animation(DS.Anim.spring, value: onboardingComplete)
        // fullScreenCover sits above UITabBar in UIKit hierarchy
        .fullScreenCover(isPresented: $showRoastOverlay) {
            MorningRoastOverlay(
                score:    FakeData.score,
                profile:  FakeData.profile,
                streak:   FakeData.streak,
                onDismiss: { showRoastOverlay = false }
            )
            .presentationBackground(.clear)
        }
    }
}

// MARK: - Main tab view

struct MainTabView: View {
    @Binding var showRoastOverlay: Bool
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(showRoastOverlay: $showRoastOverlay)
                .tabItem { Label("Home",     systemImage: "house.fill") }
                .tag(0)

            StatsView()
                .tabItem { Label("Stats",    systemImage: "chart.xyaxis.line") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(DS.Color.fireStart)
        .toolbarBackground(DS.Color.card, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
