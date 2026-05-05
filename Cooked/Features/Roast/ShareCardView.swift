import SwiftUI

// MARK: - ShareCardView
// Bottom sheet — shows preview + export button.
// Uses ImageRenderer to produce a UIImage then hands off to UIActivityViewController.

struct ShareCardView: View {
    let score:   DayScore
    let profile: UserProfile
    let streak:  Int

    @Environment(\.dismiss) private var dismiss

    @State private var isRendering = false
    @State private var renderedImage: UIImage?
    @State private var showShareSheet = false

    // Export dimensions (9:16 friendly)
    private let exportWidth:  CGFloat = 390
    private let exportHeight: CGFloat = 700
    private let exportScale:  CGFloat = 3    // 3× = 1170×2100 crisp

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            // Preview
            Text("SHARE YOUR ROAST")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)
                .padding(.top, DS.Space.lg)

            // Live card preview (smaller, centered)
            ScrollView(.vertical, showsIndicators: false) {
                RoastCard(score: score, profile: profile, streak: streak)
                    .scaleEffect(0.82)
                    .frame(
                        width:  RoastCard.cardWidth * 0.82,
                        height: 420
                    )
                    .clipped()
            }
            .frame(height: 380)

            Spacer()

            // Share button
            Button {
                Task { await renderAndShare() }
            } label: {
                HStack {
                    if isRendering {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(DS.Color.darkText)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isRendering ? "RENDERING..." : "SHARE CARD →")
                        .font(DS.Font.label(11))
                        .tracking(3)
                }
                .foregroundStyle(DS.Color.darkText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.lg)
                .background(isRendering ? DS.Color.inkSecondary : DS.Color.dark)
                .clipShape(Capsule())
            }
            .disabled(isRendering)
            .padding(.horizontal, DS.Space.lg)

            Button("Cancel") { dismiss() }
                .font(DS.Font.body(14))
                .foregroundStyle(DS.Color.inkSecondary)
                .padding(.bottom, DS.Space.xl)
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = renderedImage {
                ActivityViewController(activityItems: [img])
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Render + share

    @MainActor
    private func renderAndShare() async {
        isRendering = true
        defer { isRendering = false }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Build export card — fixed size, no dynamic sizing
        let exportCard = RoastCard(
            score:    score,
            profile:  profile,
            streak:   streak,
            isForExport: true
        )
        .frame(width: exportWidth, height: exportHeight)
        .clipped()

        let renderer = ImageRenderer(content: exportCard)
        renderer.scale = exportScale
        renderer.proposedSize = .init(width: exportWidth, height: exportHeight)

        guard let image = renderer.uiImage else {
            isRendering = false
            return
        }

        // Watermark already in card bottom row ("cooked" label)
        renderedImage = image
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showShareSheet = true
    }
}

// MARK: - UIActivityViewController wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    let score = DayScore()
    score.overall = 72; score.sleepScore = 80; score.physicalScore = 90
    score.screenScore = 60; score.schoolScore = 70; score.homeworkScore = 55
    score.roast = "You hit the gym but spent 3 hours on TikTok."
    score.tip   = "Put your phone in another room tonight."
    score.callouts = [Callout(type: .positive, emoji: "🔥", text: "Gym at 4pm")]

    return ShareCardView(score: score, profile: UserProfile(name: "Luka"), streak: 7)
}
