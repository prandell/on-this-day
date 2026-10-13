import AVFoundation
import Photos
import SwiftUI

/// Plays and loops a video `PHAsset` while it's the front card, with a bottom-left speed-cycle control.
struct VideoAssetView: View {
    let asset: PHAsset
    let isFrontCard: Bool
    @StateObject private var controller = VideoPlaybackController()

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)
            if let player = controller.player {
                PlayerLayerView(player: player)
            } else {
                ProgressView()
            }
        }
        .overlay(alignment: .bottomLeading) { speedButton }
        .task(id: asset.localIdentifier) {
            controller.isFrontCard = isFrontCard
            await controller.load(asset: asset)
        }
        .onChange(of: isFrontCard) { controller.isFrontCard = isFrontCard }
        .onDisappear { controller.teardown() }
    }

    private var speedButton: some View {
        Button { controller.cycleSpeed() } label: {
            Text(speedLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.45), in: Capsule())
        }
        .padding(.leading, 14)
        .padding(.bottom, 58) // sits above SwipeCard's year/duration caption pill, same bottom-leading corner
    }

    private var speedLabel: String {
        let speed = VideoPlaybackController.speeds[controller.speedIndex]
        return speed == speed.rounded() ? "\(Int(speed))x" : "\(speed)x"
    }
}

@MainActor
final class VideoPlaybackController: ObservableObject {
    static let speeds: [Float] = [1, 1.5, 2]

    @Published private(set) var player: AVPlayer?
    @Published private(set) var speedIndex = 0
    var isFrontCard = false { didSet { apply() } }
    private var endObserver: NSObjectProtocol?

    func load(asset: PHAsset) async {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        let item: AVPlayerItem? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
        guard let item else { return }
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.actionAtItemEnd = .none
        player = newPlayer
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            // `queue: .main` guarantees this runs on the main thread, matching SwipeSession's MainActor isolation.
            MainActor.assumeIsolated {
                guard let self else { return }
                newPlayer.seek(to: .zero)
                if self.isFrontCard { newPlayer.play() }
            }
        }
        apply()
    }

    func cycleSpeed() {
        speedIndex = (speedIndex + 1) % Self.speeds.count
        apply()
    }

    func teardown() {
        player?.pause()
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
    }

    private func apply() {
        guard let player else { return }
        if isFrontCard {
            player.rate = Self.speeds[speedIndex]
            player.play()
        } else {
            player.pause()
        }
    }

    deinit {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }
}

private final class PlayerLayerContainerView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerContainerView {
        let view = PlayerLayerContainerView()
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: PlayerLayerContainerView, context: Context) {
        view.playerLayer.player = player
    }
}
