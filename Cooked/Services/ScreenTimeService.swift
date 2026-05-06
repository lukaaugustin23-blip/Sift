import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

// MARK: - Data types

struct ScreenTimeData {
    var productiveTime: TimeInterval   // seconds in productive apps
    var wastedTime: TimeInterval       // seconds in wasted apps
    var totalTime: TimeInterval        // total screen time
    var topApp: String                 // bundle ID or display name of most-used app

    var productiveRatio: Double {
        guard totalTime > 0 else { return 0 }
        return productiveTime / totalTime
    }
}

// MARK: - ScreenTimeService
// NOTE: DeviceActivity data (per-app usage) is only accessible inside a
// DeviceActivityReport extension. This service handles:
//   1. Authorization via FamilyControls
//   2. Storing the user's productive/wasted bundle ID config
//   3. Providing ScreenTimeData to ScoringService (from extension-delivered data
//      stored in shared UserDefaults / App Group, or manual fallback)

final class ScreenTimeService: ObservableObject {

    static let shared = ScreenTimeService()
    private let center = AuthorizationCenter.shared

    // App Group shared container key for extension-delivered data
    private let suiteName = "group.com.cooked.app"
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    @Published var isAuthorized = false

    private init() {
        isAuthorized = center.authorizationStatus == .approved
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            await MainActor.run { isAuthorized = true }
        } catch {
            print("[ScreenTime] Auth failed: \(error.localizedDescription)")
            await MainActor.run { isAuthorized = false }
        }
    }

    // MARK: - Fetch screen time for a given date

    /// Primary path: reads data written by DeviceActivityReport extension.
    /// Fallback: returns zeroed data so scoring continues gracefully.
    func fetchScreenTime(
        for date: Date,
        profile: UserProfile
    ) async -> ScreenTimeData {
        // Try reading from shared container (written by DeviceActivityReport extension)
        if let stored = readStoredScreenTimeData(for: date, profile: profile) {
            return stored
        }
        // Fallback — can't query DeviceActivity directly from main app
        print("[ScreenTime] No stored data for \(date). Using empty fallback.")
        return ScreenTimeData(productiveTime: 0, wastedTime: 0, totalTime: 0, topApp: "Unknown")
    }

    // MARK: - Store / read from shared container

    /// DeviceActivityReport extension writes JSON here; main app reads it.
    func storeScreenTimeData(_ data: ScreenTimeData, for date: Date) {
        let key = storageKey(for: date)
        let dict: [String: Any] = [
            "productiveTime": data.productiveTime,
            "wastedTime":     data.wastedTime,
            "totalTime":      data.totalTime,
            "topApp":         data.topApp,
        ]
        sharedDefaults?.set(dict, forKey: key)
    }

    private func readStoredScreenTimeData(for date: Date, profile: UserProfile) -> ScreenTimeData? {
        let key = storageKey(for: date)
        guard let dict = sharedDefaults?.dictionary(forKey: key),
              let productive = dict["productiveTime"] as? TimeInterval,
              let wasted     = dict["wastedTime"]     as? TimeInterval,
              let total      = dict["totalTime"]      as? TimeInterval,
              let topApp     = dict["topApp"]         as? String
        else { return nil }

        return ScreenTimeData(
            productiveTime: productive,
            wastedTime: wasted,
            totalTime: total,
            topApp: topApp
        )
    }

    // MARK: - Categorise raw app usage (called from extension)

    /// Given a map of bundleID → seconds, split into productive/wasted
    /// based on user's profile config.
    func categorise(
        appUsage: [String: TimeInterval],
        profile: UserProfile
    ) -> ScreenTimeData {
        var productive: TimeInterval = 0
        var wasted:     TimeInterval = 0
        var total:      TimeInterval = 0
        var topApp = ""
        var topTime: TimeInterval = 0

        for (bundleId, seconds) in appUsage {
            total += seconds
            if seconds > topTime { topTime = seconds; topApp = bundleId }

            if profile.productiveAppBundleIds.contains(bundleId) {
                productive += seconds
            } else if profile.wastedAppBundleIds.contains(bundleId) {
                wasted += seconds
            }
            // Uncategorised apps don't count either way
        }

        return ScreenTimeData(
            productiveTime: productive,
            wastedTime: wasted,
            totalTime: total,
            topApp: topApp
        )
    }

    // MARK: - Helpers

    private func storageKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return "screentime_\(fmt.string(from: date))"
    }
}
