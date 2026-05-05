import SwiftUI

struct SchoolScheduleView: View {
    /// Calendar weekday ints: 1=Sun, 2=Mon … 7=Sat
    @Binding var schoolDays: [Int]
    @Binding var startTime: Date
    @Binding var endTime: Date

    var onContinue: () -> Void

    // Ordered Mon–Sun display
    private let weekdays: [(label: String, short: String, value: Int)] = [
        ("Monday",    "M",  2),
        ("Tuesday",   "T",  3),
        ("Wednesday", "W",  4),
        ("Thursday",  "T",  5),
        ("Friday",    "F",  6),
        ("Saturday",  "S",  7),
        ("Sunday",    "S",  1),
    ]

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {

                        // Header
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("SCHOOL SCHEDULE")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)

                            Text("When do you go to school?")
                                .font(DS.Font.heading(24))
                                .foregroundStyle(DS.Color.ink)
                        }

                        // Days of week picker
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("SCHOOL DAYS")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)

                            HStack(spacing: DS.Space.xs) {
                                ForEach(weekdays, id: \.value) { day in
                                    DayToggle(
                                        label: day.short,
                                        fullName: day.label,
                                        isSelected: schoolDays.contains(day.value)
                                    ) {
                                        withAnimation(DS.Animation.buttonPress) {
                                            if schoolDays.contains(day.value) {
                                                schoolDays.removeAll { $0 == day.value }
                                            } else {
                                                schoolDays.append(day.value)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Start time
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("SCHOOL HOURS")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)

                            VStack(spacing: DS.Space.xs) {
                                TimeRow(label: "Start time", time: $startTime)
                                Divider().overlay(DS.Color.inkSecondary.opacity(0.15))
                                TimeRow(label: "End time",   time: $endTime)
                            }
                            .padding(.vertical, DS.Space.xs)
                            .background(DS.Color.bgSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
                        }

                        // No school option
                        Button {
                            withAnimation(DS.Animation.buttonPress) {
                                schoolDays = []
                            }
                        } label: {
                            HStack {
                                Image(systemName: schoolDays.isEmpty
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .foregroundStyle(schoolDays.isEmpty
                                                     ? DS.Color.accent
                                                     : DS.Color.inkSecondary)
                                Text("I don't go to school")
                                    .font(DS.Font.body(15))
                                    .foregroundStyle(DS.Color.ink)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: DS.Space.xxl)
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.xl)
                    .padding(.bottom, 120)
                }

                // Continue
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
                .padding(.horizontal, DS.Space.lg)
                .padding(.bottom, DS.Space.xxl)
                .padding(.top, DS.Space.md)
                .background(DS.Color.bg)
            }
        }
    }
}

// MARK: - Day Toggle

private struct DayToggle: View {
    let label: String
    let fullName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(DS.Font.data(11))
                .foregroundStyle(isSelected ? DS.Color.darkText : DS.Color.inkSecondary)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(isSelected ? DS.Color.dark : DS.Color.bgSecondary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fullName)
    }
}

// MARK: - Time Row

private struct TimeRow: View {
    let label: String
    @Binding var time: Date

    var body: some View {
        HStack {
            Text(label.uppercased())
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)
            Spacer()
            DatePicker(
                "",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(DS.Color.accent)
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
    }
}

#Preview {
    SchoolScheduleView(
        schoolDays: .constant([2, 3, 4, 5, 6]),
        startTime:  .constant(Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!),
        endTime:    .constant(Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!),
        onContinue: {}
    )
}
