import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    @State private var editName       = ""
    @State private var editGoals      = ["", "", ""]
    @State private var editStyle:     RoastStyle = .savage
    @State private var editUncensored = false
    @State private var appeared       = false
    @State private var showResetAlert = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    Spacer().frame(height: DS.Space.sm)

                    // Title
                    Text("Settings")
                        .font(DS.Font.display(28))
                        .foregroundStyle(DS.Color.text1)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    // Profile
                    profileSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    // Goals
                    goalsSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 22)

                    // Roast style
                    roastStyleSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)

                    // Uncensored
                    uncensoredSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 26)

                    // Debug
                    debugSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 28)

                    // Version
                    versionRow
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: DS.Space.xxl)
                }
                .padding(.horizontal, DS.Space.lg)
            }
        }
        .onAppear {
            loadProfile()
            withAnimation(DS.Anim.spring.delay(0.05)) { appeared = true }
        }
        .onChange(of: editName)       { _ in saveProfile() }
        .onChange(of: editGoals)      { _ in saveProfile() }
        .onChange(of: editStyle)      { _ in saveProfile() }
        .onChange(of: editUncensored) { _ in saveProfile() }
        .alert("Reset Onboarding", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { resetOnboarding() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete your profile and all scores. You will see onboarding again on next launch.")
        }
    }

    // MARK: - Profile section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            sectionLabel("PROFILE")
            VStack(spacing: 0) {
                HStack {
                    Text("Name")
                        .font(DS.Font.label(14))
                        .foregroundStyle(DS.Color.text2)
                    Spacer()
                    TextField("Your name", text: $editName)
                        .font(DS.Font.body(14))
                        .foregroundStyle(DS.Color.text1)
                        .tint(DS.Color.fireStart)
                        .multilineTextAlignment(.trailing)
                }
                .padding(DS.Space.md)
            }
            .cardStyle()
        }
    }

    // MARK: - Goals section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            sectionLabel("YOUR GOALS")
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { i in
                    HStack {
                        Text("Goal \(i + 1)")
                            .font(DS.Font.label(13))
                            .foregroundStyle(DS.Color.text3)
                        Spacer()
                        TextField(["Med school", "Startup", "Read more"][i],
                                  text: goalBinding(i))
                            .font(DS.Font.body(13))
                            .foregroundStyle(DS.Color.text2)
                            .tint(DS.Color.fireStart)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(DS.Space.md)
                    if i < 2 {
                        Divider().background(DS.Color.cardBorder).padding(.leading, DS.Space.md)
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Roast style

    private var roastStyleSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            sectionLabel("ROAST STYLE")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.sm) {
                ForEach(RoastStyle.allCases, id: \.self) { style in
                    let selected = editStyle == style
                    Button {
                        withAnimation(DS.Anim.fast) { editStyle = style }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: DS.Space.xs) {
                            Text(style.emoji).font(.system(size: 26))
                            Text(style.displayName)
                                .font(DS.Font.label(11))
                                .foregroundStyle(selected ? DS.Color.text1 : DS.Color.text2)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.md)
                        .background(DS.Color.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.inner))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.inner)
                                .strokeBorder(
                                    selected
                                        ? AnyShapeStyle(DS.Gradient.fire)
                                        : AnyShapeStyle(DS.Color.cardBorder),
                                    lineWidth: selected ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Uncensored

    private var uncensoredSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Uncensored Mode")
                    .font(DS.Font.label(14))
                    .foregroundStyle(DS.Color.text1)
                Text("Full roast, no filter.")
                    .font(DS.Font.body(12))
                    .foregroundStyle(DS.Color.text3)
            }
            Spacer()
            Toggle("", isOn: $editUncensored)
                .tint(DS.Color.fireStart)
                .labelsHidden()
        }
        .padding(DS.Space.md)
        .cardStyle()
    }

    // MARK: - Debug

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            sectionLabel("DEBUG")
            Button {
                showResetAlert = true
            } label: {
                HStack {
                    Text("Reset Onboarding")
                        .font(DS.Font.label(14))
                        .foregroundStyle(DS.Color.fireStart)
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Color.fireStart)
                }
                .padding(DS.Space.md)
                .cardStyle()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Version

    private var versionRow: some View {
        HStack {
            Spacer()
            VStack(spacing: 3) {
                HStack(spacing: 0) {
                    Text("cook").font(DS.Font.label(12)).foregroundStyle(DS.Color.text3)
                    Text("ed.").font(DS.Font.label(12)).gradientText(DS.Gradient.fire)
                }
                Text("Version 1.0.0")
                    .font(DS.Font.body(11))
                    .foregroundStyle(DS.Color.text3)
            }
            Spacer()
        }
        .padding(.top, DS.Space.md)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.label(10))
            .foregroundStyle(DS.Color.text3)
            .kerning(1.5)
    }

    private func goalBinding(_ i: Int) -> Binding<String> {
        Binding(
            get: { i < editGoals.count ? editGoals[i] : "" },
            set: { v in
                while editGoals.count <= i { editGoals.append("") }
                editGoals[i] = v
            }
        )
    }

    private func loadProfile() {
        guard let p = profile else { return }
        editName       = p.name
        editGoals      = p.goals + Array(repeating: "", count: max(0, 3 - p.goals.count))
        editStyle      = p.roastStyle
        editUncensored = p.uncensoredMode
    }

    private func saveProfile() {
        guard let p = profile else { return }
        p.name            = editName
        p.goals           = editGoals.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        p.roastStyle      = editStyle
        p.uncensoredMode  = editUncensored
        try? modelContext.save()
    }

    private func resetOnboarding() {
        for score in (try? modelContext.fetch(FetchDescriptor<DayScore>())) ?? [] {
            modelContext.delete(score)
        }
        for prof in profiles { modelContext.delete(prof) }
        try? modelContext.save()
        UserDefaults.standard.removeObject(forKey: "rateLimitDate")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self, DayScore.self], inMemory: true)
}
