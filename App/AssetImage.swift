import Photos
import SwiftUI

struct AssetImage: View {
    let asset: PHAsset
    var isFrontCard: Bool = true
    @Environment(\.displayScale) private var scale
    @State private var image: UIImage?

    var body: some View {
        if asset.mediaType == .video {
            VideoAssetView(asset: asset, isFrontCard: isFrontCard)
        } else {
            GeometryReader { geo in
                ZStack {
                    Color(.secondarySystemBackground)
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        ProgressView()
                    }
                }
                .task(id: asset.localIdentifier) {
                    let size = CGSize(width: max(geo.size.width, 200) * scale, height: max(geo.size.height, 200) * scale)
                    image = await ImageLoader.image(for: asset, size: size)
                }
            }
            .contentShape(Rectangle())
        }
    }
}

enum ImageLoader {
    static func image(for asset: PHAsset, size: CGSize) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true // pulls from iCloud when "Optimise Storage" is on
        return await withCheckedContinuation { continuation in
            var resumed = false
            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: image)
            }
        }
    }
}
