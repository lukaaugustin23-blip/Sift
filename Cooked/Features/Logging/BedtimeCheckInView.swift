import SwiftUI
import SwiftData

struct BedtimeCheckInView: View {
    let log: DayLog

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var doomscrolled: Bool? = nil   // nil = not answered yet
    @State private var savedWithHaptic = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {

            // Header
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("BEDTIME CHECK-IN")
                    .font(DS.Font.heading(20))
                    .foregroundStyle(DS.Color.ink)
                Text("Be honest. The data knows.")
                    .font(DS.Font.body(14))
                    .foregroundStyle(DS.Color.inkSecondary)
            }

            // The question
            VStack(spacing: DS.Space.md) {
                Text("Did you doomscroll\nin bed tonight?")
                    .font(DS.Font.hero(32))
                    .foregroundStyle(DS.Color.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.lg)
            }

            // Big YES / NO
            HStack(spacing: DS.Space.md) {
                DoomscrollButton(
                    emoji: "💀",
                    label: "YES",
                    sublabel: "owned it",
                    color: DS.Color.danger,
                    isSelected: doomscrolled == true
                ) {
                    haptic(.heavy)
                    withAnimation(DS.Animation.buttonPress) {
                        doomscrolled = true
                    }
                    autoSave(after: 0.4)
                }

                DoomscrollButton(
                    emoji: "✅",
                    label: "NO",
                    sublabel: "locked in",
                    color: DS.Color.accent,
                    isSelected: doomscrolled == false
                ) {
                    haptic()
                    withAnimation(DS.Animation.buttonPress) {
                        doomscrolled = false
                    }
                    autoSave(after: 0.4)
                }
            }
            .frame(maxWidth: .infinity)

            // Confirmation state
            if savedWithHaptic {
                HStack {
                    Spacer()
                    VStack(spacing: DS.Space.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DS.Color.accent)
                            .font(.system(size: 28))
                        Text("LOGGED")
                            .labelStyle()
                            .foregroundStyle(DS.Color.accent)
                    }
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Manual save (if they haven't tapped yet)
            if doomscrolled != nil && !savedWithHaptic {
                Button {
                    saveAndDismiss()
                } label: {
                    Text("SAVE →")
                        .font(DS.Font.label(11))
                        .foregroundStyle(DS.Color.darkText)
                        .tracking(3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.lg)
                        .background(DS.Color.dark)
                        .clipShape(Capsule())
                }
            }

            // Skip
            Button {
                dismiss()
            } label: {
                Text("Skip for now")
                    .font(DS.Font.body(14))
                    .foregroundStyle(DS.Color.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, DS.Space.xl)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.top, DS.Space.lg)
        .animation(DS.Animation.cardEntrance, value: doomscrolled)
        .animation(DS.Animation.cardEntrance, value: savedWithHaptic)
        .onAppear {
            doomscrolled = log.doomscrolledInBed ? true : nil
        }
    }

    // MARK: - Helpers

    /// Saves after a short delay so button animation plays first
    private func autoSave(after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard doomscrolled != nil else { return }
            log.doomscrolledInBed = doomscrolled == true
            log.lastModified      = Date()
            try? modelContext.save()

            withAnimation(DS.Animation.cardEntrance) {
                savedWithHaptic = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismiss()
            }
        }
    }

    private func saveAndDismiss() {
        haptic()
        log.doomscrolledInBed = doomscrolled == true
        log.lastModified      = Date()
        try? modelContext.save()
        dismiss()
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Big doomscroll answer button

private struct DoomscrollButton: View {
    let emoji:      String
    let label:      String
    let sublabel:   String
    let color:      Color
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Space.sm) {
                Text(emoji)
                    .font(.system(size: 44))

                Text(label)
                    .font(DS.Font.hero(28))
                    .foregroundStyle(isSelected ? color : DS.Color.inkSecondary)

                Text(sublabel.uppercased())
                    .font(DS.Font.label(8))
                    .foregroundStyle(isSelected ? color.opacity(0.8) : DS.Color.inkSecondary)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.xl)
            .background(isSelected ? color.opacity(0.08) : DS.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(DS.Animation.buttonPress, value: isSelected)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayLog.self, configurations: config)
    let log = DayLog()
    container.mainContext.insert(log)
    return BedtimeCheckInView(log: log)
        .modelContainer(container)
        .presentationBackground(DS.Color.bg)
}
