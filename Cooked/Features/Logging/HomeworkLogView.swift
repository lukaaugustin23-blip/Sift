import SwiftUI
import SwiftData

struct HomeworkLogView: View {
    let log: DayLog

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var didHomework:   Bool = false
    @State private var didFinish:     Bool = true
    @State private var delayMinutes:  Int  = 0     // 15-min steps

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {

            Text("HOMEWORK")
                .font(DS.Font.heading(20))
                .foregroundStyle(DS.Color.ink)

            // Did homework?
            didHomeworkSection

            // If yes — details
            if didHomework {
                delaySection
                    .transition(.move(edge: .top).combined(with: .opacity))

                finishedSection
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()

            saveButton
                .padding(.bottom, DS.Space.xl)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.top, DS.Space.lg)
        .animation(DS.Animation.cardEntrance, value: didHomework)
        .onAppear { loadExisting() }
    }

    // MARK: - Did homework

    private var didHomeworkSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("DID YOU DO HOMEWORK TODAY?")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            HStack(spacing: DS.Space.sm) {
                BigToggleButton(label: "YES ✅", isSelected: didHomework) {
                    haptic()
                    withAnimation { didHomework = true }
                }
                BigToggleButton(label: "NO ❌", isSelected: !didHomework) {
                    haptic()
                    withAnimation { didHomework = false }
                }
            }
        }
    }

    // MARK: - Delay stepper

    private var delaySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("HOW LONG AFTER GETTING HOME?")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            HStack {
                Button {
                    haptic(.light)
                    if delayMinutes > 0 { delayMinutes -= 15 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(delayMinutes > 0 ? DS.Color.inkSecondary : DS.Color.trackBg)
                }
                .buttonStyle(.plain)
                .disabled(delayMinutes == 0)

                Spacer()

                VStack(spacing: 2) {
                    Text(delayLabel)
                        .font(DS.Font.heading(22))
                        .foregroundStyle(delayColor)
                        .contentTransition(.numericText())
                        .animation(DS.Animation.buttonPress, value: delayMinutes)
                    Text("DELAY")
                        .labelStyle()
                        .foregroundStyle(DS.Color.inkSecondary)
                }

                Spacer()

                Button {
                    haptic(.light)
                    if delayMinutes < 300 { delayMinutes += 15 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DS.Color.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(DS.Space.md)
            .background(DS.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
        }
    }

    // MARK: - Did finish

    private var finishedSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("DID YOU FINISH IT?")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            HStack(spacing: DS.Space.sm) {
                BigToggleButton(label: "DONE ✅", isSelected: didFinish) {
                    haptic(.light)
                    didFinish = true
                }
                BigToggleButton(label: "PARTIAL ⚠️", isSelected: !didFinish) {
                    haptic(.light)
                    didFinish = false
                }
            }
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            haptic()
            log.homeworkCompleted = didHomework && didFinish
            log.homeworkDelay     = didHomework ? TimeInterval(delayMinutes * 60) : nil
            log.lastModified      = Date()
            try? modelContext.save()
            dismiss()
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

    // MARK: - Helpers

    private var delayLabel: String {
        if delayMinutes == 0    { return "Right away" }
        if delayMinutes < 60    { return "\(delayMinutes)min" }
        let h = delayMinutes / 60
        let m = delayMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private var delayColor: Color {
        switch delayMinutes {
        case 0..<30:   return DS.Color.accent
        case 30..<90:  return DS.Color.ink
        default:       return DS.Color.danger
        }
    }

    private func loadExisting() {
        if let completed = log.homeworkCompleted as Bool? {
            didHomework  = completed || (log.homeworkDelay != nil)
            didFinish    = completed
        }
        if let delay = log.homeworkDelay {
            delayMinutes = Int(delay / 60)
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Big toggle button

private struct BigToggleButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(DS.Font.label(10))
                .foregroundStyle(isSelected ? DS.Color.darkText : DS.Color.inkSecondary)
                .tracking(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.lg)
                .background(isSelected ? DS.Color.dark : DS.Color.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(DS.Animation.buttonPress, value: isSelected)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayLog.self, configurations: config)
    let log = DayLog()
    container.mainContext.insert(log)
    return HomeworkLogView(log: log)
        .modelContainer(container)
        .presentationBackground(DS.Color.bg)
}
