import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    @Attribute(.externalStorage) var goals: [String]        // up to 3
    var roastStyle: RoastStyle
    var uncensoredMode: Bool
    @Attribute(.externalStorage) var productiveAppBundleIds: [String]
    @Attribute(.externalStorage) var wastedAppBundleIds: [String]
    var onboardingCompleted: Bool
    var createdAt: Date

    init(
        name: String = "",
        goals: [String] = ["", "", ""],
        roastStyle: RoastStyle = .savage,
        uncensoredMode: Bool = false,
        productiveAppBundleIds: [String] = [],
        wastedAppBundleIds: [String] = [],
        onboardingCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.name = name
        self.goals = goals
        self.roastStyle = roastStyle
        self.uncensoredMode = uncensoredMode
        self.productiveAppBundleIds = productiveAppBundleIds
        self.wastedAppBundleIds = wastedAppBundleIds
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
    }
}
