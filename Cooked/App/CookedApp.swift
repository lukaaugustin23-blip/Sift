import SwiftUI

@main
struct CookedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()
            VStack(spacing: DS.Space.lg) {
                Text("COOKED")
                    .font(DS.Font.hero())
                    .foregroundStyle(DS.Color.ink)
                Text("Loading...")
                    .font(DS.Font.label())
                    .foregroundStyle(DS.Color.inkSecondary)
                    .labelStyle()
            }
        }
    }
}
