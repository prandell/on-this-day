import Photos
import SwiftUI

struct SwipeCard: View {
    let asset: PHAsset
    let onDecide: (SwipeSession.Decision) -> Void
    /// Signed drag progress, -1 (full delete) ... 1 (full keep), so the screen around the card can react too.
    @Binding var dragAmount: CGFloat
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            AssetImage(asset: asset)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay(alignment: .topTrailing) { yearsAgoBadge }
                .overlay(alignment: .bottomLeading) { videoDurationBadge }
                .offset(offset)
                .rotationEffect(.degrees(Double(offset.width / 20)))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                            dragAmount = max(-1, min(1, value.translation.width / (geo.size.width * 0.5)))
                        }
                        .onEnded { value in
                            let threshold = geo.size.width * 0.28
                            if value.translation.width > threshold { fling(.keep, width: geo.size.width) }
                            else if value.translation.width < -threshold { fling(.delete, width: geo.size.width) }
                            else { withAnimation(.spring) { offset = .zero; dragAmount = 0 } }
                        }
                )
        }
    }

    private func fling(_ decision: SwipeSession.Decision, width: CGFloat) {
        withAnimation(.easeOut(duration: 0.2)) {
            offset.width = (decision == .keep ? 1 : -1) * width * 1.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDecide(decision)
            dragAmount = 0
        }
    }

    @ViewBuilder
    private var yearsAgoBadge: some View {
        if let date = asset.creationDate {
            let years = Calendar.current.dateComponents([.year], from: date, to: .now).year ?? 0
            Text("\(years) YR. AGO")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(14)
        }
    }

    @ViewBuilder
    private var videoDurationBadge: some View {
        if asset.mediaType == .video {
            Label(Duration.seconds(asset.duration).formatted(.time(pattern: .minuteSecond)), systemImage: "play.fill")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(14)
        }
    }
}
