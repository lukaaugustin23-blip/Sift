import SwiftUI

// MARK: - App category state

enum AppCategory: String, CaseIterable {
    case productive, wasted, ignore

    var label: String {
        switch self {
        case .productive: return "✅"
        case .wasted:     return "🚫"
        case .ignore:     return "—"
        }
    }

    var color: Color {
        switch self {
        case .productive: return DS.Color.accent
        case .wasted:     return DS.Color.danger
        case .ignore:     return DS.Color.inkSecondary
        }
    }
}

// MARK: - Preset app list

struct AppEntry: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    let defaultCategory: AppCategory
}

private let presetApps: [AppEntry] = [
    // Social / Entertainment (default wasted)
    AppEntry(name: "TikTok",       bundleId: "com.zhiliaoapp.musically",     defaultCategory: .wasted),
    AppEntry(name: "Instagram",    bundleId: "com.burbn.instagram",          defaultCategory: .wasted),
    AppEntry(name: "Snapchat",     bundleId: "com.toyopagroup.picaboo",      defaultCategory: .wasted),
    AppEntry(name: "X / Twitter",  bundleId: "com.atebits.Tweetie2",        defaultCategory: .wasted),
    AppEntry(name: "YouTube",      bundleId: "com.google.ios.youtube",       defaultCategory: .wasted),
    AppEntry(name: "Netflix",      bundleId: "com.netflix.Netflix",          defaultCategory: .wasted),
    AppEntry(name: "Discord",      bundleId: "com.hammerandchisel.discord",  defaultCategory: .wasted),
    AppEntry(name: "Reddit",       bundleId: "com.reddit.Reddit",            defaultCategory: .wasted),
    AppEntry(name: "BeReal",       bundleId: "AlexisBarreyat.BeReal",        defaultCategory: .wasted),

    // Productivity (default productive)
    AppEntry(name: "Notion",       bundleId: "notion.id",                    defaultCategory: .productive),
    AppEntry(name: "Khan Academy", bundleId: "org.khanacademy.Khan-Academy", defaultCategory: .productive),
    AppEntry(name: "Duolingo",     bundleId: "com.duolingo.DuolingoMobile",  defaultCategory: .productive),
    AppEntry(name: "Anki",         bundleId: "com.ankimobile.AnkiMobile",    defaultCategory: .productive),
    AppEntry(name: "Kindle",       bundleId: "com.amazon.Lassen",            defaultCategory: .productive),
    AppEntry(name: "Headspace",    bundleId: "com.getsomeheadspace.android", defaultCategory: .productive),
    AppEntry(name: "Google Docs",  bundleId: "com.google.GoogleDocs",        defaultCategory: .productive),
    AppEntry(name: "Xcode",        bundleId: "com.apple.dt.Xcode",           defaultCategory: .productive),

    // Neutral (default ignore)
    AppEntry(name: "Apple Maps",   bundleId: "com.apple.Maps",               defaultCategory: .ignore),
    AppEntry(name: "Messages",     bundleId: "com.apple.MobileSMS",          defaultCategory: .ignore),
    AppEntry(name: "Spotify",      bundleId: "com.spotify.client",           defaultCategory: .ignore),
    AppEntry(name: "Apple Music",  bundleId: "com.apple.Music",              defaultCategory: .ignore),
    AppEntry(name: "Camera",       bundleId: "com.apple.camera",             defaultCategory: .ignore),
]

// MARK: - AppCategorizationView

struct AppCategorizationView: View {
    @Binding var productiveIds: [String]
    @Binding var wastedIds: [String]

    var onContinue: () -> Void

    @State private var categories: [String: AppCategory] = [:]

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Legend
                legendBar

                // App list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(presetApps) { app in
                            AppRow(
                                app: app,
                                category: categories[app.bundleId] ?? app.defaultCategory
                            ) { newCategory in
                                withAnimation(DS.Animation.buttonPress) {
                                    categories[app.bundleId] = newCategory
                                }
                            }

                            if app.id != presetApps.last?.id {
                                Divider()
                                    .overlay(DS.Color.inkSecondary.opacity(0.1))
                                    .padding(.leading, DS.Space.lg)
                            }
                        }
                    }
                    .background(DS.Color.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.vertical, DS.Space.md)
                    .padding(.bottom, 100)
                }

                // Continue
                Button(action: {
                    saveCategories()
                    onContinue()
                }) {
                    Text("CONTINUE →")
                        .font(DS.Font.label(11))
                        .foregroundStyle(DS.Color.darkText)
                        .tracking(3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.lg)
                        .background(DS.Color.dark)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.bottom, DS.Space.xxl)
                .padding(.top, DS.Space.md)
                .background(DS.Color.bg)
            }
        }
        .onAppear { initCategories() }
        .navigationBarHidden(true)
    }

    // MARK: - Legend

    private var legendBar: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text("APP CATEGORIES")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            Text("Mark each app productive, wasted, or ignore.")
                .font(DS.Font.body(14))
                .foregroundStyle(DS.Color.ink)

            HStack(spacing: DS.Space.lg) {
                ForEach(AppCategory.allCases, id: \.self) { cat in
                    HStack(spacing: DS.Space.xs) {
                        Text(cat.label).font(.system(size: 14))
                        Text(cat.rawValue.uppercased())
                            .font(DS.Font.label(9))
                            .foregroundStyle(cat.color)
                            .tracking(2)
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.top, DS.Space.xl)
        .padding(.bottom, DS.Space.sm)
    }

    // MARK: - Helpers

    private func initCategories() {
        for app in presetApps {
            categories[app.bundleId] = app.defaultCategory
        }
        // Restore any previously set values
        for id in productiveIds { categories[id] = .productive }
        for id in wastedIds     { categories[id] = .wasted }
    }

    private func saveCategories() {
        productiveIds = categories.filter { $0.value == .productive }.map(\.key)
        wastedIds     = categories.filter { $0.value == .wasted }.map(\.key)
    }
}

// MARK: - App Row

private struct AppRow: View {
    let app: AppEntry
    let category: AppCategory
    let onChange: (AppCategory) -> Void

    var body: some View {
        HStack(spacing: DS.Space.md) {
            // App name
            Text(app.name)
                .font(DS.Font.body(15))
                .foregroundStyle(DS.Color.ink)

            Spacer()

            // 3-way segmented control
            HStack(spacing: 4) {
                ForEach(AppCategory.allCases, id: \.self) { cat in
                    Button {
                        onChange(cat)
                    } label: {
                        Text(cat.label)
                            .font(.system(size: 13))
                            .frame(width: 36, height: 32)
                            .background(
                                category == cat
                                    ? cat.color.opacity(0.15)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        category == cat ? cat.color : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
        .contentShape(Rectangle())
    }
}

#Preview {
    AppCategorizationView(
        productiveIds: .constant([]),
        wastedIds:     .constant([]),
        onContinue:    {}
    )
}
