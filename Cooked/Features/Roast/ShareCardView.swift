import SwiftUI

struct ShareCardView: View {
    let score:   DayScore
    let profile: UserProfile
    let streak:  Int

    @Environment(\.dismiss) private var dismiss

    @State private var isRendering  = false
    @State private var showActivity = false
    @State private var rendered:    UIImage? = nil

    private let exportWidth:  CGFloat = 390
    private let exportHeight: CGFloat = 700
    private let exportScale:  CGFloat = 3

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            Text("SHARE YOUR ROAST")
                .labelStyle()
                .foregroundStyle(DS.Color.inkSecondary)
                .padding(.top, DS.Space.lg)

            // Preview
            ScrollView(.vertical, showsIndicators: false) {
                RoastCard(score: score, profile: profile, streak: streak)
                    .scaleEffect(0.82)
                    .frame(width: RoastCard.cardWidth * 0.82, height: 380)
                    .clipped()
            }
            .frame(height: 340)

            Spacer()

            // Share button
            Button {
                Task { await renderAndShare() }
            } label: {
                HStack(spacing: DS.Space.sm) {
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
                .background(isRendering ? DS.Color.inkSecondary : DS.Color.ink)
                .clipShape(Capsule())
            }
            .disabled(isRendering)
            .padding(.horizontal, DS.Space.lg)

            Button("Cancel") { dismiss() }
                .font(DS.Font.body(14))
                .foregroundStyle(DS.Color.inkSecondary)
                .padding(.bottom, DS.Space.xl)
        }
        .sheet(isPresented: $showActivity) {
            if let img = rendered {
                ActivityViewController(activityItems: [img]).ignoresSafeArea()
            }
        }
    }

    @MainActor
    private func renderAndShare() async {
        isRendering = true
        defer { isRendering = false }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let card = RoastCard(score: score, profile: profile, streak: streak, isForExport: true)
            .frame(width: exportWidth, height: exportHeight)
            .clipped()

        let renderer = ImageRenderer(content: card)
        renderer.scale = exportScale
        renderer.proposedSize = .init(width: exportWidth, height: exportHeight)

        guard let img = renderer.uiImage else { return }
        rendered = img
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showActivity = true
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    let s = DayScore(overall: 72, productiveTime: 7200, wastedTime: 5400,
                     roast: "You spent more time on TikTok than on anything productive.",
                     tip: "Delete TikTok from your home screen tonight.")
    return ShareCardView(score: s, profile: UserProfile(name: "Luka"), streak: 7)
}
