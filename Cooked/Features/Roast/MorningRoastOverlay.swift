import SwiftUI

// MARK: - Morning Roast Overlay
// Full-screen overlay that pops up on first open.
// Spring slide-up from bottom + rotation + scale + pulsing fire glow.

struct MorningRoastOverlay: View {
    let score:   DayScore
    let profile: UserProfile
    let streak:  Int
    let onDismiss: () -> Void

    // Animation states
    @State private var cardOffset:   CGFloat = 800
    @State private var cardRotation: Double  = 2.0
    @State private var cardScale:    CGFloat = 0.90
    @State private var bgOpacity:    CGFloat = 0
    @State private var glowRadius:   CGFloat = 18
    @State private var glowOpacity:  CGFloat = 0.45

    @State private var showShare = false
    @State private var rendered: UIImage? = nil
    @State private var isRendering = false

    // Swipe-to-dismiss
    @State private var dragOffset: CGFloat = 0

    private var isGoodScore: Bool { score.overall >= 60 }
    private var scoreGrad: LinearGradient { isGoodScore ? DS.Gradient.teal : DS.Gradient.fire }
    private var borderClr: Color { isGoodScore ? DS.Color.tealStart : DS.Color.fireStart }

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.75 * bgOpacity)
                .ignoresSafeArea()
                .onTapGesture { } // absorb taps behind card

            // Card
            ScrollView(showsIndicators: false) {
                cardContent
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.xl)
                    .padding(.bottom, DS.Space.xxl)
            }
            .offset(y: cardOffset + dragOffset)
            .rotationEffect(.degrees(cardRotation))
            .scaleEffect(cardScale)
            .shadow(
                color: DS.Color.fireStart.opacity(glowOpacity),
                radius: glowRadius, x: 0, y: 0
            )
            .gesture(
                DragGesture()
                    .onChanged { v in
                        if v.translation.height > 0 { dragOffset = v.translation.height }
                    }
                    .onEnded { v in
                        if v.translation.height > 110 {
                            dismiss()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            // 0.3s delay then spring in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) {
                    cardOffset   = 0
                    cardRotation = 0
                    cardScale    = 1.0
                    bgOpacity    = 1
                }
            }
            // Continuous glow pulse
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    glowRadius  = 38
                    glowOpacity = 0.75
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let img = rendered {
                ActivityViewController(activityItems: [img]).ignoresSafeArea()
            }
        }
    }

    // MARK: - Card content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            headerRow

            VStack(alignment: .leading, spacing: DS.Space.lg) {
                // Score block
                scoreBlock

                // Roast section
                roastSection

                // Callout tags
                calloutTags

                // Stats row
                statsRow

                // Bars
                barsSection

                // Bottom row
                bottomRow
            }
            .padding(DS.Space.lg)
        }
        .background(DS.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .strokeBorder(DS.Color.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            // Logo
            HStack(spacing: 0) {
                Text("cook")
                    .font(DS.Font.display(18))
                    .foregroundStyle(DS.Color.text1)
                Text("ed.")
                    .font(DS.Font.display(18))
                    .gradientText(DS.Gradient.fire)
            }
            Spacer()
            // Date
            Text(score.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(DS.Font.body(12))
                .foregroundStyle(DS.Color.text3)
            Spacer()
            // X dismiss
            Button(action: dismiss) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 30, height: 30)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Color.text2)
                }
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.bg.opacity(0.5))
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.Color.cardBorder).frame(height: 1)
        }
    }

    // MARK: - Score

    private var scoreBlock: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(score.overall)")
                        .font(DS.Font.display(88))
                        .gradientText(scoreGrad)
                    Text("/100")
                        .font(DS.Font.display(20))
                        .foregroundStyle(DS.Color.text3)
                        .padding(.bottom, 10)
                }
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.badge)
                    .fill(scoreGrad)
                    .frame(width: 58, height: 58)
                Text(score.grade)
                    .font(DS.Font.display(28))
                    .foregroundStyle(.white)
            }
            .shadow(color: borderClr.opacity(0.5), radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Roast

    private var roastSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("TODAY'S ROAST")
                .font(DS.Font.label(9))
                .gradientText(DS.Gradient.fire)
                .kerning(1.5)

            HStack(alignment: .top, spacing: DS.Space.sm) {
                Rectangle()
                    .fill(borderClr)
                    .frame(width: 2)
                    .clipShape(Capsule())
                Text(score.roast)
                    .font(DS.Font.bodyItalic(13.5))
                    .foregroundStyle(DS.Color.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Callout tags

    private var calloutTags: some View {
        FlowLayout(spacing: DS.Space.xs) {
            ForEach(score.callouts) { callout in
                HStack(spacing: 4) {
                    Text(callout.emoji)
                        .font(.system(size: 11))
                    Text(callout.text)
                        .font(DS.Font.label(11))
                        .if(callout.type == .negative) { $0.gradientText(DS.Gradient.fire) }
                        .if(callout.type == .positive) { $0.gradientText(DS.Gradient.teal) }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    callout.type == .negative
                        ? DS.Color.fireStart.opacity(0.12)
                        : DS.Color.tealStart.opacity(0.12)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        callout.type == .negative
                            ? DS.Color.fireStart.opacity(0.25)
                            : DS.Color.tealStart.opacity(0.25),
                        lineWidth: 1
                    )
                )
            }
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: DS.Space.sm) {
            miniStat("PRODUCTIVE", score.productiveFormatted, DS.Gradient.teal)
            miniStat("WASTED",     score.wastedFormatted,     DS.Gradient.fire)
            miniStat("TOP APP",    score.topWastedApp.isEmpty ? "—" : score.topWastedApp, DS.Gradient.fire)
        }
    }

    private func miniStat(_ label: String, _ value: String, _ grad: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DS.Font.label(8))
                .foregroundStyle(DS.Color.text3)
                .kerning(1)
            Text(value)
                .font(DS.Font.display(13))
                .gradientText(grad)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.md)
        .background(DS.Color.bg)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.inner))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.inner)
                .strokeBorder(DS.Color.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Bars

    private var barsSection: some View {
        VStack(spacing: DS.Space.md) {
            animBar("Productive", score.productiveFormatted,
                    CGFloat(score.productiveTime / max(score.totalScreenTime, 1)),
                    DS.Gradient.teal)
            Divider().background(DS.Color.cardBorder)
            animBar("Wasted", score.wastedFormatted,
                    CGFloat(score.wastedTime / max(score.totalScreenTime, 1)),
                    DS.Gradient.fire)
        }
        .padding(DS.Space.md)
        .background(DS.Color.bg)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.inner))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.inner)
                .strokeBorder(DS.Color.cardBorder, lineWidth: 1)
        )
    }

    private func animBar(_ label: String, _ value: String, _ ratio: CGFloat, _ grad: LinearGradient) -> some View {
        VStack(spacing: DS.Space.sm) {
            HStack {
                Text(label).font(DS.Font.label(11)).foregroundStyle(DS.Color.text2)
                Spacer()
                Text(value).font(DS.Font.label(11)).foregroundStyle(DS.Color.text2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Color.text3.opacity(0.12)).frame(height: 6)
                    Capsule().fill(grad)
                        .frame(width: max(geo.size.width * ratio, ratio > 0 ? 8 : 0), height: 6)
                        .animation(.spring(response: 1.0, dampingFraction: 0.75).delay(0.7), value: ratio)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Bottom row

    private var bottomRow: some View {
        HStack(spacing: DS.Space.md) {
            // Streak
            HStack(spacing: DS.Space.xs) {
                Text("🔥")
                    .font(.system(size: 16))
                HStack(spacing: 4) {
                    Text("\(streak)")
                        .font(DS.Font.display(15))
                        .gradientText(DS.Gradient.fire)
                    Text("day streak")
                        .font(DS.Font.body(12))
                        .foregroundStyle(DS.Color.text3)
                }
            }
            Spacer()
            // Share button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await renderAndShare() }
            } label: {
                HStack(spacing: DS.Space.xs) {
                    if isRendering {
                        ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.7)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text(isRendering ? "Rendering..." : "Share Card →")
                        .font(DS.Font.label(12))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.sm + 2)
                .background(DS.Gradient.fire)
                .clipShape(Capsule())
            }
            .disabled(isRendering)
        }
    }

    // MARK: - Actions

    private func dismiss() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            cardOffset  = 900
            cardRotation = -1
            bgOpacity   = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onDismiss() }
    }

    @MainActor
    private func renderAndShare() async {
        isRendering = true
        defer { isRendering = false }

        let card = RoastCard(score: score, profile: profile, streak: streak, isForExport: true)
            .frame(width: 390, height: 700)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.proposedSize = .init(width: 390, height: 700)
        guard let img = renderer.uiImage else { return }
        rendered = img
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showShare = true
    }
}

// MARK: - Flow layout for callout chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0; var x: CGFloat = 0; var rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += rowH + spacing; x = 0; rowH = 0
            }
            rowH = max(rowH, size.height); x += size.width + spacing
        }
        height += rowH
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowH + spacing; x = bounds.minX; rowH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            rowH = max(rowH, size.height); x += size.width + spacing
        }
    }
}

#Preview {
    MorningRoastOverlay(
        score: FakeData.score,
        profile: FakeData.profile,
        streak: FakeData.streak,
        onDismiss: {}
    )
    .background(DS.Color.bg)
}
