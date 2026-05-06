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
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            VStack(spacing: DS.Space.lg) {
                // Title
                Text("SHARE YOUR ROAST")
                    .font(DS.Font.label(11))
                    .foregroundStyle(DS.Color.text3)
                    .kerning(2)
                    .padding(.top, DS.Space.lg)

                // Preview
                ScrollView(.vertical, showsIndicators: false) {
                    RoastCard(score: score, profile: profile, streak: streak)
                        .scaleEffect(0.8)
                        .frame(height: 360)
                        .clipped()
                }
                .frame(height: 320)

                Spacer()

                // Share button
                Button {
                    Task { await renderAndShare() }
                } label: {
                    HStack(spacing: DS.Space.sm) {
                        if isRendering {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isRendering ? "Rendering..." : "Share Card →")
                    }
                    .fireButtonStyle()
                }
                .shadow(color: DS.Color.fireStart.opacity(0.35), radius: 16, x: 0, y: 6)
                .disabled(isRendering)
                .opacity(isRendering ? 0.6 : 1)
                .padding(.horizontal, DS.Space.lg)

                Button("Cancel") { dismiss() }
                    .font(DS.Font.body(14))
                    .foregroundStyle(DS.Color.text3)
                    .padding(.bottom, DS.Space.xl)
            }
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
                     roast: "You spent more time watching strangers than touching grass.",
                     tip: "Delete TikTok from your home screen tonight.")
    return ShareCardView(score: s, profile: UserProfile(name: "Luka"), streak: 5)
}
