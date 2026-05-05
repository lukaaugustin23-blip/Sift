import SwiftUI
import SwiftData

struct QuickLogView: View {
    let log: DayLog

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    private let activityTags = ["Reading", "Side project", "Meditation", "Journaling", "Art", "Music", "Coding", "Other"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                sheetHandle

                // School attendance
                schoolSection

                // Free periods
                freePeriodsSection

                // Extra activities
                extraActivitiesSection

                // Done button
                doneButton
                    .padding(.top, DS.Space.sm)
                    .padding(.bottom, DS.Space.xl)
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.top, DS.Space.lg)
        }
    }

    // MARK: - School section

    private var schoolSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("SCHOOL")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            HStack(spacing: DS.Space.sm) {
                ToggleChip(label: "Attended ✅", isOn: log.schoolAttended) {
                    haptic()
                    log.schoolAttended = true
                    save()
                }
                ToggleChip(label: "Skipped ❌", isOn: !log.schoolAttended) {
                    haptic()
                    log.schoolAttended = false
                    save()
                }
            }
        }
    }

    // MARK: - Free periods

    private var freePeriodsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            HStack {
                Text("FREE PERIODS")
                    .labelStyle()
                    .foregroundStyle(DS.Color.inkSecondary)

                Spacer()

                Text("\(log.freePeriods.count) logged")
                    .font(DS.Font.data(10))
                    .foregroundStyle(DS.Color.inkSecondary)
            }

            // Logged periods chips
            if !log.freePeriods.isEmpty {
                FlowLayout(spacing: DS.Space.xs) {
                    ForEach(log.freePeriods) { period in
                        PeriodChip(period: period) {
                            haptic(.light)
                            log.freePeriods.removeAll { $0.id == period.id }
                            save()
                        }
                    }
                }
            }

            // Add period buttons — max 2 taps
            HStack(spacing: DS.Space.sm) {
                Button {
                    haptic()
                    log.freePeriods.append(FreePeriod(quality: .productive))
                    save()
                } label: {
                    Label("Productive", systemImage: "plus")
                        .font(DS.Font.label(9))
                        .foregroundStyle(DS.Color.accent)
                        .tracking(2)
                        .padding(.horizontal, DS.Space.md)
                        .padding(.vertical, DS.Space.sm)
                        .background(DS.Color.calloutPositiveBg)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    haptic()
                    log.freePeriods.append(FreePeriod(quality: .wasted))
                    save()
                } label: {
                    Label("Wasted", systemImage: "plus")
                        .font(DS.Font.label(9))
                        .foregroundStyle(DS.Color.danger)
                        .tracking(2)
                        .padding(.horizontal, DS.Space.md)
                        .padding(.vertical, DS.Space.sm)
                        .background(DS.Color.calloutNegativeBg)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Extra activities

    private var extraActivitiesSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("EXTRA ACTIVITIES")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)

            FlowLayout(spacing: DS.Space.xs) {
                ForEach(activityTags, id: \.self) { tag in
                    let isActive = log.extraActivities.contains(tag)
                    Button {
                        haptic(.light)
                        if isActive {
                            log.extraActivities.removeAll { $0 == tag }
                        } else {
                            log.extraActivities.append(tag)
                        }
                        save()
                    } label: {
                        Text(tag.uppercased())
                            .font(DS.Font.label(8))
                            .foregroundStyle(isActive ? DS.Color.accent : DS.Color.inkSecondary)
                            .tracking(2)
                            .padding(.horizontal, DS.Space.md)
                            .padding(.vertical, DS.Space.sm)
                            .background(isActive ? DS.Color.calloutPositiveBg : DS.Color.bgSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isActive ? DS.Color.accent : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(DS.Animation.buttonPress, value: isActive)
                }
            }
        }
    }

    // MARK: - Done

    private var doneButton: some View {
        Button {
            haptic()
            save()
            dismiss()
        } label: {
            Text("DONE")
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

    private var sheetHandle: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text("LOG YOUR DAY")
                .font(DS.Font.heading(20))
                .foregroundStyle(DS.Color.ink)
        }
    }

    private func save() {
        log.lastModified = Date()
        try? modelContext.save()
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Toggle Chip

private struct ToggleChip: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(DS.Font.label(9))
                .foregroundStyle(isOn ? DS.Color.ink : DS.Color.inkSecondary)
                .tracking(2)
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.sm)
                .background(isOn ? DS.Color.bgSecondary : DS.Color.bgSecondary.opacity(0.5))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isOn ? DS.Color.ink : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .animation(DS.Animation.buttonPress, value: isOn)
    }
}

// MARK: - Period Chip

private struct PeriodChip: View {
    let period: FreePeriod
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(period.quality == .productive ? "✅" : "🚫")
                .font(.system(size: 12))
            Text(period.quality.rawValue.uppercased())
                .font(DS.Font.label(8))
                .foregroundStyle(period.quality == .productive ? DS.Color.accent : DS.Color.danger)
                .tracking(2)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.inkSecondary)
            }
        }
        .padding(.horizontal, DS.Space.sm)
        .padding(.vertical, 6)
        .background(period.quality == .productive
                    ? DS.Color.calloutPositiveBg
                    : DS.Color.calloutNegativeBg)
        .clipShape(Capsule())
    }
}

// MARK: - Flow layout (wrapping chip grid)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
