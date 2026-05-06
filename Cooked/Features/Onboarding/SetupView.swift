import SwiftUI

struct SetupView: View {
    @Binding var name: String
    @Binding var goals: [String]
    @Binding var roastStyle: RoastStyle
    @Binding var uncensored: Bool
    let onDone: () -> Void

    @FocusState private var focusedField: Field?
    @State private var appeared = false

    private enum Field: Hashable {
        case name, goal(Int)
    }

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    Spacer().frame(height: DS.Space.lg)

                    // Title
                    Text("About you.")
                        .font(DS.Font.display(28))
                        .foregroundStyle(DS.Color.text1)
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : -20)

                    // Name field
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        sectionLabel("YOUR NAME")
                        darkField(
                            text: $name,
                            placeholder: "Your name",
                            focus: .name
                        )
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -16)

                    // Goals
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        sectionLabel("YOUR GOALS")
                        ForEach(0..<3, id: \.self) { i in
                            darkField(
                                text: binding(for: i),
                                placeholder: goalPlaceholder(i),
                                focus: .goal(i)
                            )
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -12)

                    // Roast style
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        sectionLabel("ROAST STYLE")
                        roastStyleGrid
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -8)

                    // Uncensored toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Uncensored mode")
                                .font(DS.Font.label(14))
                                .foregroundStyle(DS.Color.text1)
                            Text("No filter. Full roast.")
                                .font(DS.Font.body(12))
                                .foregroundStyle(DS.Color.text3)
                        }
                        Spacer()
                        Toggle("", isOn: $uncensored)
                            .tint(DS.Color.fireStart)
                            .labelsHidden()
                    }
                    .padding(DS.Space.md)
                    .innerCardStyle()
                    .opacity(appeared ? 1 : 0)

                    // Done button
                    Button(action: onDone) {
                        Text("Done →")
                            .fireButtonStyle()
                    }
                    .shadow(color: DS.Color.fireStart.opacity(0.30), radius: 16, x: 0, y: 6)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: DS.Space.xxl)
                }
                .padding(.horizontal, DS.Space.lg)
            }
        }
        .onAppear {
            withAnimation(DS.Anim.spring.delay(0.08)) { appeared = true }
        }
    }

    // MARK: - Subviews

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.label(10))
            .foregroundStyle(DS.Color.text3)
            .kerning(1.5)
    }

    private func darkField(text: Binding<String>, placeholder: String, focus: Field) -> some View {
        TextField(placeholder, text: text)
            .font(DS.Font.body(15))
            .foregroundStyle(DS.Color.text1)
            .tint(DS.Color.fireStart)
            .padding(DS.Space.md)
            .background(DS.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        focusedField == focus
                            ? AnyShapeStyle(DS.Gradient.fire)
                            : AnyShapeStyle(DS.Color.cardBorder),
                        lineWidth: focusedField == focus ? 1.5 : 1
                    )
            )
            .focused($focusedField, equals: focus)
    }

    private var roastStyleGrid: some View {
        let styles = RoastStyle.allCases
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.sm) {
            ForEach(styles, id: \.self) { style in
                roastStyleCard(style)
            }
        }
    }

    private func roastStyleCard(_ style: RoastStyle) -> some View {
        let selected = roastStyle == style
        return Button {
            withAnimation(DS.Anim.fast) { roastStyle = style }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: DS.Space.xs) {
                Text(style.emoji)
                    .font(.system(size: 28))
                Text(style.displayName)
                    .font(DS.Font.label(12))
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

    // MARK: - Helpers

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { index < goals.count ? goals[index] : "" },
            set: { val in
                while goals.count <= index { goals.append("") }
                goals[index] = val
            }
        )
    }

    private func goalPlaceholder(_ i: Int) -> String {
        ["e.g. get into med school", "e.g. build my startup", "e.g. read 20 books"][i]
    }
}

#Preview {
    SetupView(
        name: .constant("Luka"),
        goals: .constant(["", "", ""]),
        roastStyle: .constant(.savage),
        uncensored: .constant(false),
        onDone: {}
    )
}
