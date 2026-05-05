import SwiftUI

// MARK: - App category

enum AppCategory: String, CaseIterable {
    case productive, wasted, ignore

    var emoji: String {
        switch self {
        case .productive: return "✅"
        case .wasted:     return "🚫"
        case .ignore:     return "—"
        }
    }

    var label: String {
        switch self {
        case .productive: return "Good"
        case .wasted:     return "Wasted"
        case .ignore:     return "Ignore"
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

// MARK: - Preset apps

struct AppEntry: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    let defaultCategory: AppCategory
}

private let presetApps: [AppEntry] = [
    // Wasted defaults
    AppEntry(name: "TikTok",       bundleId: "com.zhiliaoapp.musically",     defaultCategory: .wasted),
    AppEntry(name: "Instagram",    bundleId: "com.burbn.instagram",          defaultCategory: .wasted),
    AppEntry(name: "Snapchat",     bundleId: "com.toyopagroup.picaboo",      defaultCategory: .wasted),
    AppEntry(name: "X / Twitter",  bundleId: "com.atebits.Tweetie2",        defaultCategory: .wasted),
    AppEntry(name: "YouTube",      bundleId: "com.google.ios.youtube",       defaultCategory: .wasted),
    AppEntry(name: "Netflix",      bundleId: "com.netflix.Netflix",          defaultCategory: .wasted),
    AppEntry(name: "Discord",      bundleId: "com.hammerandchisel.discord",  defaultCategory: .wasted),
    AppEntry(name: "Reddit",       bundleId: "com.reddit.Reddit",            defaultCategory: .wasted),
    AppEntry(name: "BeReal",       bundleId: "AlexisBarreyat.BeReal",        defaultCategory: .wasted),
    // Productive defaults
    AppEntry(name: "Notion",       bundleId: "notion.id",                    defaultCategory: .productive),
    AppEntry(name: "Khan Academy", bundleId: "org.khanacademy.Khan-Academy", defaultCategory: .productive),
    AppEntry(name: "Duolingo",     bundleId: "com.duolingo.DuolingoMobile",  defaultCategory: .productive),
    AppEntry(name: "Anki",         bundleId: "com.ankimobile.AnkiMobile",    defaultCategory: .productive),
    AppEntry(name: "Kindle",       bundleId: "com.amazon.Lassen",            defaultCategory: .productive),
    AppEntry(name: "Headspace",    bundleId: "com.getsomeheadspace.android", defaultCategory: .productive),
    AppEntry(name: "Google Docs",  bundleId: "com.google.GoogleDocs",        defaultCategory: .productive),
    // Ignore defaults
    AppEntry(name: "Messages",     bundleId: "com.apple.MobileSMS",          defaultCategory: .ignore),
    AppEntry(name: "Spotify",      bundleId: "com.spotify.client",           defaultCategory: .ignore),
    AppEntry(name: "Apple Music",  bundleId: "com.apple.Music",              defaultCategory: .ignore),
    AppEntry(name: "Apple Maps",   bundleId: "com.apple.Maps",               defaultCategory: .ignore),
    AppEntry(name: "Camera",       bundleId: "com.apple.camera",             defaultCategory: .ignore),
]

// MARK: - View

struct AppCategorizationView: View {
    @Binding var productiveIds: [String]
    @Binding var wastedIds: [String]

    var onContinue: () -> Void

    @State private var categories: [String: AppCategory] = [:]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                DS.Color.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {

                        // ── Header ─────────────────────────────────────────
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("APP CATEGORIES")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)
                            Text("What counts as\nproductive for you?")
                                .font(DS.Font.hero(min(geo.size.width * 0.115, 46)))
                                .foregroundStyle(DS.Color.ink)
                                .lineSpacing(2)
                        }

                        // ── Legend ─────────────────────────────────────────
                        HStack(spacing: DS.Space.lg) {
                            ForEach(AppCategory.allCases, id: \.self) { cat in
                                HStack(spacing: 6) {
                                    Text(cat.emoji).font(.system(size: 13))
                                    Text(cat.label.uppercased())
                                        .font(DS.Font.label(8))
                                        .foregroundStyle(cat.color)
                                        .tracking(2)
                                }
                            }
                        }

                        // ── App list ───────────────────────────────────────
                        VStack(spacing: 0) {
                            ForEach(Array(presetApps.enumerated()), id: \.element.id) { idx, app in
                                AppRow(
                                    app: app,
                                    category: categories[app.bundleId] ?? app.defaultCategory,
                                    onChange: { newCat in
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(DS.Animation.buttonPress) {
                                            categories[app.bundleId] = newCat
                                        }
                                    }
                                )
                                if idx < presetApps.count - 1 {
                                    Divider()
                                        .overlay(Color.black.opacity(0.05))
                                        .padding(.leading, DS.Space.md)
                                }
                            }
                        }
                        .cardStyle()

                        Spacer(minLength: 140)
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, geo.size.height * 0.06)
                }

                // ── Continue ───────────────────────────────────────────────
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [DS.Color.bg.opacity(0), DS.Color.bg],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)

                    Button(action: {
                        saveCategories()
                        onContinue()
                    }) {
                        Text("DONE →")
                            .primaryButtonStyle()
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.bottom, geo.safeAreaInsets.bottom + DS.Space.md)
                    .background(DS.Color.bg)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear { initCategories() }
    }

    private func initCategories() {
        for app in presetApps { categories[app.bundleId] = app.defaultCategory }
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
            Text(app.name)
                .font(DS.Font.body(15))
                .foregroundStyle(DS.Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(AppCategory.allCases, id: \.self) { cat in
                    Button { onChange(cat) } label: {
                        Text(cat.emoji)
                            .font(.system(size: 15))
                            .frame(width: 42, height: 36)
                            .background(category == cat ? cat.color.opacity(0.12) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        category == cat ? cat.color : Color.black.opacity(0.08),
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
    AppCategorizationView(productiveIds: .constant([]), wastedIds: .constant([]), onContinue: {})
}
