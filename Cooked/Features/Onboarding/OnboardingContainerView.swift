import SwiftUI
import SwiftData

// MARK: - Steps

private enum OnboardingStep: Int, CaseIterable {
    case welcome        = 0
    case nameGoals      = 1
    case roastStyle     = 2
    case schoolSchedule = 3
    case appCategories  = 4

    var showsProgressBar: Bool { self != .welcome }

    /// Progress 0.0 → 1.0 (welcome doesn't count)
    var progress: Double {
        let steps = Double(OnboardingStep.allCases.count - 1)
        return Double(rawValue) / steps
    }
}

// MARK: - OnboardingContainerView

struct OnboardingContainerView: View {
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    // MARK: Collected data
    @State private var step:           OnboardingStep = .welcome
    @State private var name:           String         = ""
    @State private var goals:          [String]       = ["", "", ""]
    @State private var roastStyle:     RoastStyle     = .savage
    @State private var uncensored:     Bool           = false
    @State private var schoolDays:     [Int]          = [2, 3, 4, 5, 6]
    @State private var startTime:      Date           = defaultTime(hour: 8)
    @State private var endTime:        Date           = defaultTime(hour: 15)
    @State private var productiveIds:  [String]       = []
    @State private var wastedIds:      [String]       = []

    // MARK: Animation
    @State private var slideDirection: Edge = .trailing

    var body: some View {
        ZStack(alignment: .top) {
            DS.Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (hidden on welcome)
                if step.showsProgressBar {
                    progressBar
                        .transition(.opacity)
                }

                // Screen content
                currentScreen
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: slideDirection),
                            removal:   .move(edge: slideDirection == .trailing ? .leading : .trailing)
                        )
                    )
            }
        }
        .animation(DS.Animation.cardEntrance, value: step)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(DS.Color.trackBg)
                    .frame(height: 2)

                Rectangle()
                    .fill(DS.Color.accent)
                    .frame(width: geo.size.width * step.progress, height: 2)
                    .animation(DS.Animation.barFill, value: step.progress)
            }
        }
        .frame(height: 2)
    }

    // MARK: - Current screen

    @ViewBuilder
    private var currentScreen: some View {
        switch step {
        case .welcome:
            WelcomeView {
                advance(to: .nameGoals)
            }

        case .nameGoals:
            NameGoalsView(
                name:  $name,
                goals: $goals,
                onContinue: { advance(to: .roastStyle) }
            )

        case .roastStyle:
            RoastStyleView(
                selected:   $roastStyle,
                uncensored: $uncensored,
                onContinue: { advance(to: .schoolSchedule) }
            )

        case .schoolSchedule:
            SchoolScheduleView(
                schoolDays: $schoolDays,
                startTime:  $startTime,
                endTime:    $endTime,
                onContinue: { advance(to: .appCategories) }
            )

        case .appCategories:
            AppCategorizationView(
                productiveIds: $productiveIds,
                wastedIds:     $wastedIds,
                onContinue:    { completeOnboarding() }
            )
        }
    }

    // MARK: - Navigation

    private func advance(to next: OnboardingStep) {
        slideDirection = .trailing
        withAnimation(DS.Animation.cardEntrance) {
            step = next
        }
    }

    // MARK: - Completion — persist UserProfile

    private func completeOnboarding() {
        let profile = UserProfile(name: name)

        // Goals — strip blanks
        profile.goals = goals.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }

        profile.roastStyle        = roastStyle
        profile.uncensoredMode    = uncensored
        profile.schoolDays        = schoolDays
        profile.schoolStartTime   = startTime.secondsFromMidnight
        profile.schoolEndTime     = endTime.secondsFromMidnight
        profile.productiveAppBundleIds = productiveIds
        profile.wastedAppBundleIds     = wastedIds
        profile.typicalWorkouts        = []
        profile.onboardingCompleted    = true

        modelContext.insert(profile)

        do {
            try modelContext.save()
        } catch {
            print("[Onboarding] Failed to save profile: \(error)")
        }

        onComplete()
    }

    // MARK: - Helpers

    private static func defaultTime(hour: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour, minute: 0, second: 0, of: Date()
        ) ?? Date()
    }
}

// MARK: - Date helper

private extension Date {
    /// Seconds since midnight for storing in UserProfile
    var secondsFromMidnight: TimeInterval {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: self)
        return TimeInterval((comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60)
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
}
