import SwiftUI

struct RoastStyleView: View {
    @Binding var selected: RoastStyle
    @Binding var uncensored: Bool

    var onContinue: () -> Void

    private let styles: [(RoastStyle, String, String)] = [
        (.savage,             "💀", "No mercy. Pull no punches."),
        (.disappointedParent, "😞", "Expected so much more from you."),
        (.coach,              "📣", "Furious, but still believes in you."),
        (.sarcastic,          "🙄", "Dripping with irony."),
    ]

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {

                        // Header
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("ROAST STYLE")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)

                            Text("How do you want to be called out?")
                                .font(DS.Font.heading(24))
                                .foregroundStyle(DS.Color.ink)
                        }

                        // Style cards
                        VStack(spacing: DS.Space.sm) {
                            ForEach(styles, id: \.0) { style, emoji, subtitle in
                                StyleCard(
                                    style: style,
                                    emoji: emoji,
                                    subtitle: subtitle,
                                    isSelected: selected == style
                                ) {
                                    withAnimation(DS.Animation.buttonPress) {
                                        selected = style
                                    }
                                }
                            }
                        }

                        // Uncensored toggle
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("SETTINGS")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Uncensored Mode")
                                        .font(DS.Font.bodyMedium(15))
                                        .foregroundStyle(DS.Color.ink)
                                    Text("Allows swearing in roasts")
                                        .font(DS.Font.body(13))
                                        .foregroundStyle(DS.Color.inkSecondary)
                                }
                                Spacer()
                                Toggle("", isOn: $uncensored)
                                    .tint(DS.Color.accent)
                                    .labelsHidden()
                            }
                            .padding(DS.Space.md)
                            .background(DS.Color.bgSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
                        }

                        Spacer(minLength: DS.Space.xxl)
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.xl)
                    .padding(.bottom, 120)
                }

                // Continue
                continueButton
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.bottom, DS.Space.xxl)
                    .padding(.top, DS.Space.md)
                    .background(DS.Color.bg)
            }
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("CONTINUE →")
                .font(DS.Font.label(11))
                .foregroundStyle(DS.Color.darkText)
                .tracking(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.lg)
                .background(DS.Color.dark)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Style Card

private struct StyleCard: View {
    let style: RoastStyle
    let emoji: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DS.Space.md) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected ? DS.Color.dark : DS.Color.bgSecondary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.displayName.uppercased())
                        .font(DS.Font.label(10))
                        .foregroundStyle(isSelected ? DS.Color.ink : DS.Color.inkSecondary)
                        .tracking(3)

                    Text(subtitle)
                        .font(DS.Font.body(14))
                        .foregroundStyle(DS.Color.ink)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? DS.Color.accent : DS.Color.inkSecondary)
                    .font(.system(size: 20))
            }
            .padding(DS.Space.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.tag)
                    .fill(DS.Color.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.tag)
                            .stroke(
                                isSelected ? DS.Color.accent : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(DS.Animation.buttonPress, value: isSelected)
    }
}

#Preview {
    RoastStyleView(
        selected: .constant(.savage),
        uncensored: .constant(false),
        onContinue: {}
    )
}
