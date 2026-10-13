import Photos
import SwiftUI

struct SwipeCard: View {
    let asset: PHAsset
    let onDecide: (DayDeck.Decision) -> Void
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            AssetImage(asset: asset)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(alignment: .bottomLeading) { caption }
                .overlay { stamp }
                .offset(offset)
                .rotationEffect(.degrees(Double(offset.width / 20)))
                .gesture(
                    DragGesture()
                        .onChanged { offset = $0.translation }
                        .onEnded { value in
                            let threshold = geo.size.width * 0.28
                            if value.translation.width > threshold { fling(.keep, width: geo.size.width) }
                            else if value.translation.width < -threshold { fling(.delete, width: geo.size.width) }
                            else { withAnimation(.spring) { offset = .zero } }
                        }
                )
        }
    }

    private func fling(_ decision: DayDeck.Decision, width: CGFloat) {
        withAnimation(.easeOut(duration: 0.2)) {
            offset.width = (decision == .keep ? 1 : -1) * width * 1.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDecide(decision) }
    }

    private var caption: some View {
        HStack(spacing: 6) {
            if let date = asset.creationDate {
                let years = Calendar.current.dateComponents([.year], from: date, to: .now).year ?? 0
                Text("\(date.formatted(.dateTime.year())) · \(years == 1 ? "1 year ago" : "\(years) years ago")")
            }
            if asset.mediaType == .video {
                Label(Duration.seconds(asset.duration).formatted(.time(pattern: .minuteSecond)), systemImage: "play.fill")
            }
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(10)
        .background(.black.opacity(0.45), in: Capsule())
        .padding(14)
    }

    private var stamp: some View {
        let progress = min(abs(offset.width) / 120, 1)
        let keep = offset.width > 0
        return Text(keep ? "KEEP" : "DELETE")
            .font(.system(size: 40, weight: .heavy))
            .foregroundStyle(keep ? .green : .red)
            .padding(.horizontal, 16).padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(keep ? .green : .red, lineWidth: 5))
            .rotationEffect(.degrees(keep ? -15 : 15))
            .opacity(progress)
    }
}
