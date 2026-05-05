import SwiftUI
import SwiftData

struct WorkoutLogView: View {
    let log: DayLog

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    private let workoutTypes = [
        ("Weightlifting", "🏋️"),
        ("Run",           "🏃"),
        ("Basketball",    "🏀"),
        ("Swimming",      "🏊"),
        ("Cycling",       "🚴"),
        ("Yoga",          "🧘"),
        ("Walk",          "🚶"),
        ("Other",         "⚡️"),
    ]

    @State private var selectedType  = "Weightlifting"
    @State private var durationMins  = 30       // minutes, 15-min steps
    @State private var startTime     = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {

            // Header
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("LOG WORKOUT")
                    .font(DS.Font.heading(20))
                    .foregroundStyle(DS.Color.ink)
            }

            // Type grid
            typeGrid

            // Duration stepper
            durationSection

            // Start time
            startTimeSection

            Spacer()

            // Save button
            saveButton
                .padding(.bottom, DS.Space.xl)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.top, DS.Space.lg)
    }

    // MARK: - Type grid

    private var typeGrid: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("TYPE")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: DS.Space.xs), count: 4),
                      spacing: DS.Space.xs) {
                ForEach(workoutTypes, id: \.0) { type, emoji in
                    WorkoutTypeCell(
                        label: type,
                        emoji: emoji,
                        isSelected: selectedType == type
                    ) {
                        haptic(.light)
                        selectedType = type
                    }
                }
            }
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("DURATION")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            HStack {
                Button {
                    haptic(.light)
                    if durationMins > 15 { durationMins -= 15 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 2) {
                    Text("\(durationMins)")
                        .font(DS.Font.display(52))
                        .foregroundStyle(DS.Color.ink)
                        .contentTransition(.numericText())
                    Text("MINUTES")
                        .labelStyle()
                        .foregroundStyle(DS.Color.inkSecondary)
                }

                Spacer()

                Button {
                    haptic(.light)
                    if durationMins < 240 { durationMins += 15 }
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

    // MARK: - Start time

    private var startTimeSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("START TIME")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            HStack {
                Text("Started at")
                    .font(DS.Font.body(15))
                    .foregroundStyle(DS.Color.ink)
                Spacer()
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(DS.Color.accent)
            }
            .padding(DS.Space.md)
            .background(DS.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            haptic()
            let workout = WorkoutLog(
                type: selectedType,
                duration: TimeInterval(durationMins * 60),
                startTime: startTime
            )
            log.workouts.append(workout)
            log.lastModified = Date()
            try? modelContext.save()
            dismiss()
        } label: {
            Text("SAVE WORKOUT →")
                .font(DS.Font.label(11))
                .foregroundStyle(DS.Color.darkText)
                .tracking(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.lg)
                .background(DS.Color.dark)
                .clipShape(Capsule())
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Workout type cell

private struct WorkoutTypeCell: View {
    let label: String
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 22))
                Text(label.uppercased())
                    .font(DS.Font.label(7))
                    .foregroundStyle(isSelected ? DS.Color.ink : DS.Color.inkSecondary)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.sm)
            .background(isSelected ? DS.Color.dark.opacity(0.08) : DS.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.tag)
                    .stroke(isSelected ? DS.Color.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(DS.Animation.buttonPress, value: isSelected)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayLog.self, configurations: config)
    let log = DayLog()
    container.mainContext.insert(log)
    return WorkoutLogView(log: log)
        .modelContainer(container)
        .presentationBackground(DS.Color.bg)
}
