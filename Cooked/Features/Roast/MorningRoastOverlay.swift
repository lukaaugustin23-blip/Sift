import SwiftUI

struct MorningRoastOverlay: View {
    let score:     DayScore
    let profile:   UserProfile
    let streak:    Int
    let onDismiss: () -> Void

    @State private var cardOffset:   CGFloat = 800
    @State private var cardRotation: Double  = 2.0
    @State private var cardScale:    CGFloat = 0.90
    @State private var bgOpacity:    CGFloat = 0
    @State private var glowRadius:   CGFloat = 18
    @State private var glowOpacity:  CGFloat = 0.45
    @State private var dragOffset:   CGFloat = 0
    @State private var showShare     = false
    @State private var rendered:     UIImage? = nil
    @State private var isRendering   = false

    private var isGood:    Bool              { score.overall >= 60 }
    private var scoreGrad: LinearGradient    { isGood ? DS.Gradient.teal : DS.Gradient.fire }
    private var borderClr: Color             { isGood ? DS.Color.tealStart : DS.Color.fireStart }
    private var topApp:    String            {
        score.topWastedApp.isEmpty ? "Unknown" : score.topWastedApp
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.78 * bgOpacity)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                cardContent
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.xl + DS.Space.sm)
                    .padding(.bottom, DS.Space.xxl)
            }
            .offset(y: cardOffset + dragOffset)
            .rotationEffect(.degrees(cardRotation))
            .scaleEffect(cardScale)
            .shadow(color: DS.Color.fireStart.opacity(glowOpacity), radius: glowRadius, x: 0, y: 0)
            .gesture(
                DragGesture()
                    .onChanged { v in
                        if v.translation.height > 0 { dragOffset = v.translation.height }
                    }
                    .onEnded { v in
                        if v.translation.height > 110 { dismiss() }
                        else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { dragOffset = 0 }
                        }
                    }
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) {
                    cardOffset = 0; cardRotation = 0; cardScale = 1; bgOpacity = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    glowRadius = 38; glowOpacity = 0.72
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let img = rendered {
                ActivityViewController(activityItems: [img]).ignoresSafeArea()
            }
        }
    }

    // MARK: - Card

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow

            VStack(alignment: .leading, spacing: DS.Space.xl) {
                // Score
                scoreBlock

                // Roast
                roastSection

                // Callout tags — 2 per row grid
                calloutGrid

                // Bars (with top app label above)
                barsSection

                // Bottom
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
            HStack(spacing: 0) {
                Text("cook").font(DS.Font.display(18)).foregroundStyle(DS.Color.text1)
                Text("ed.").font(DS.Font.display(18)).gradientText(DS.Gradient.fire)
            }
            Spacer()
            Text(score.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(DS.Font.body(12))
                .foregroundStyle(DS.Color.text3)
            Spacer()
            Button(action: dismiss) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.08)).frame(width: 30, height: 30)
                    Image(systemName: "xmark").font(.system(size: 12, weight: .semibold)).foregroundStyle(DS.Color.text2)
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
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(score.overall)")
                    .font(DS.Font.display(88))
                    .gradientText(scoreGrad)
                Text("/100")
                    .font(DS.Font.display(20))
                    .foregroundStyle(DS.Color.text3)
                    .padding(.bottom, 10)
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

    // MARK: - Callout grid (2 per row)

    private var calloutGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: DS.Space.sm
        ) {
            ForEach(score.callouts) { callout in
                HStack(spacing: 6) {
                    Text(callout.emoji).font(.system(size: 13))
                    Text(callout.text)
                        .font(DS.Font.label(12))
                        .if(callout.type == .negative) { $0.gradientText(DS.Gradient.fire) }
                        .if(callout.type == .positive)  { $0.gradientText(DS.Gradient.teal) }
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, DS.Space.sm + 2)
                .padding(.vertical, DS.Space.sm)
                .background(
                    callout.type == .negative
                        ? DS.Color.fireStart.opacity(0.10)
                        : DS.Color.tealStart.opacity(0.10)
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag + 2))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.tag + 2)
                        .strokeBorder(
                            callout.type == .negative
                                ? DS.Color.fireStart.opacity(0.22)
                                : DS.Color.tealStart.opacity(0.22),
                            lineWidth: 1
                        )
                )
            }
        }
    }

    // MARK: - Bars (no stat boxes, top app label above)

    private var barsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            // Top app label
            HStack(spacing: DS.Space.xs) {
                Text("TOP APP")
                    .font(DS.Font.label(9))
                    .foregroundStyle(DS.Color.text3)
                    .kerning(1.2)
                Text(topApp)
                    .font(DS.Font.label(9))
                    .gradientText(DS.Gradient.fire)
            }

            // Bars
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
                        .animation(.spring(response: 1.0, dampingFraction: 0.75).delay(0.8), value: ratio)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Bottom row

    private var bottomRow: some View {
        HStack(spacing: DS.Space.md) {
            HStack(spacing: DS.Space.xs) {
                Text("🔥").font(.system(size: 16))
                Text("\(streak)").font(DS.Font.display(15)).gradientText(DS.Gradient.fire)
                Text("day streak").font(DS.Font.body(12)).foregroundStyle(DS.Color.text3)
            }
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await renderAndShare() }
            } label: {
                HStack(spacing: DS.Space.xs) {
                    if isRendering {
                        ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.7)
                    } else {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 12, weight: .semibold))
                    }
                    Text(isRendering ? "Rendering..." : "Share Card →").font(DS.Font.label(12))
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
            cardOffset = 900; cardRotation = -1; bgOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onDismiss() }
    }

    @MainActor
    private func renderAndShare() async {
        isRendering = true; defer { isRendering = false }
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

#Preview {
    MorningRoastOverlay(score: FakeData.score, profile: FakeData.profile, streak: FakeData.streak, onDismiss: {})
        .background(DS.Color.bg)
}
