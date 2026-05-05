import SwiftUI

// MARK: - SetupView
// Screen 2: name + goals + roast style + uncensored toggle — all in one.

struct SetupView: View {
    @Binding var name: String
    @Binding var goals: [String]
    @Binding var roastStyle: RoastStyle
    @Binding var uncensored: Bool

    var onContinue: () -> Void

    @FocusState private var focus: FocusField?

    private enum FocusField: Hashable {
        case name, goal(Int)
    }

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                DS.Color.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {

                        // ── Header ─────────────────────────────────────────
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("SET UP")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)
                            Text("Tell us about\nyourself.")
                                .font(DS.Font.hero(min(geo.size.width * 0.115, 46)))
                                .foregroundStyle(DS.Color.ink)
                                .lineSpacing(2)
                        }

                        // ── Name ───────────────────────────────────────────
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            sectionLabel("YOUR NAME")

                            TextField("", text: $name,
                                      prompt: Text("Enter your name")
                                          .foregroundStyle(DS.Color.inkSecondary))
                                .font(DS.Font.heading(22))
                                .foregroundStyle(DS.Color.ink)
                                .focused($focus, equals: .name)
                                .submitLabel(.next)
                                .onSubmit { focus = .goal(0) }
                                .autocorrectionDisabled()
                                .padding(DS.Space.lg)
                                .cardStyle()
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.card)
                                        .stroke(focus == .name ? DS.Color.accent : Color.clear, lineWidth: 1.5)
                                )
                        }

                        // ── Goals ──────────────────────────────────────────
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            VStack(alignment: .leading, spacing: 2) {
                                sectionLabel("YOUR GOALS")
                                Text("What are you working toward? (up to 3)")
                                    .font(DS.Font.body(13))
                                    .foregroundStyle(DS.Color.inkSecondary)
                            }

                            ForEach(0..<3, id: \.self) { i in
                                goalRow(index: i)
                            }
                        }

                        // ── Roast Style ────────────────────────────────────
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            sectionLabel("ROAST STYLE")

                            VStack(spacing: DS.Space.sm) {
                                ForEach(RoastStyle.allCases, id: \.self) { style in
                                    StyleCard(style: style, isSelected: roastStyle == style) {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(DS.Animation.buttonPress) {
                                            roastStyle = style
                                        }
                                    }
                                }
                            }
                        }

                        // ── Uncensored ─────────────────────────────────────
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("UNCENSORED MODE")
                                    .labelStyle()
                                    .foregroundStyle(DS.Color.ink)
                                Text("Allows swearing in roasts")
                                    .font(DS.Font.body(14))
                                    .foregroundStyle(DS.Color.inkSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $uncensored)
                                .tint(DS.Color.accent)
                                .labelsHidden()
                        }
                        .padding(DS.Space.lg)
                        .cardStyle()

                        Spacer(minLength: 140)
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, geo.size.height * 0.06)
                }

                // ── Continue ───────────────────────────────────────────────
                bottomBar(geo: geo)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            if goals.count < 3 { goals = Array(repeating: "", count: 3) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focus = .name }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .labelStyle()
            .foregroundStyle(DS.Color.inkSecondary)
    }

    @ViewBuilder
    private func goalRow(index: Int) -> some View {
        HStack(spacing: DS.Space.md) {
            Text("\(index + 1)")
                .font(DS.Font.data(11))
                .foregroundStyle(DS.Color.inkSecondary)
                .frame(width: 18, alignment: .center)

            TextField("", text: Binding(
                get: { goals.indices.contains(index) ? goals[index] : "" },
                set: { goals[index] = $0 }
            ), prompt: Text(index == 0 ? "e.g. Hit the gym 4× a week" : "Optional goal")
                .foregroundStyle(DS.Color.inkSecondary))
                .font(DS.Font.body(16))
                .foregroundStyle(DS.Color.ink)
                .focused($focus, equals: .goal(index))
                .submitLabel(index < 2 ? .next : .done)
                .onSubmit {
                    if index < 2 { focus = .goal(index + 1) }
                    else { focus = nil }
                }
        }
        .padding(DS.Space.md)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(focus == .goal(index) ? DS.Color.accent : Color.clear, lineWidth: 1.5)
        )
        .animation(DS.Animation.buttonPress, value: focus == .goal(index))
    }

    @ViewBuilder
    private func bottomBar(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [DS.Color.bg.opacity(0), DS.Color.bg],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 40)
            .allowsHitTesting(false)

            Button(action: onContinue) {
                Text("CONTINUE →")
                    .primaryButtonStyle()
                    .opacity(canContinue ? 1 : 0.4)
            }
            .disabled(!canContinue)
            .padding(.horizontal, DS.Space.lg)
            .padding(.bottom, geo.safeAreaInsets.bottom + DS.Space.md)
            .background(DS.Color.bg)
        }
    }
}

// MARK: - Style Card

private struct StyleCard: View {
    let style: RoastStyle
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DS.Space.md) {
                Text(style.emoji)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(isSelected ? DS.Color.bg.opacity(0.2) : DS.Color.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName.uppercased())
                        .font(DS.Font.label(9))
                        .foregroundStyle(isSelected ? DS.Color.darkText : DS.Color.inkSecondary)
                        .tracking(3)
                    Text(style.subtitle)
                        .font(DS.Font.body(14))
                        .foregroundStyle(isSelected ? DS.Color.darkText : DS.Color.ink)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.darkText)
                }
            }
            .padding(DS.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? DS.Color.ink : DS.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .shadow(
                color: isSelected ? DS.Color.ink.opacity(0.3) : .black.opacity(0.06),
                radius: isSelected ? 24 : 16,
                x: 0,
                y: isSelected ? 8 : 4
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(DS.Animation.buttonPress, value: isSelected)
    }
}

#Preview {
    SetupView(
        name: .constant("Luka"),
        goals: .constant(["Get into med school", "", ""]),
        roastStyle: .constant(.savage),
        uncensored: .constant(false),
        onContinue: {}
    )
}
