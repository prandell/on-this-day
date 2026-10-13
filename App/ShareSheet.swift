import AVFoundation
import Photos
import SwiftUI
import UniformTypeIdentifiers

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Exports a `PHAsset` to a temporary file URL suitable for `UIActivityViewController`.
enum ShareItemLoader {
    static func url(for asset: PHAsset) async -> URL? {
        if asset.mediaType == .video {
            return await videoURL(for: asset)
        } else {
            return await imageURL(for: asset)
        }
    }

    private static func videoURL(for asset: PHAsset) async -> URL? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                continuation.resume(returning: (avAsset as? AVURLAsset)?.url)
            }
        }
    }

    private static func imageURL(for asset: PHAsset) async -> URL? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, uti, _, _ in
                guard let data else { continuation.resume(returning: nil); return }
                let ext = uti.flatMap { UTType($0)?.preferredFilenameExtension } ?? "jpg"
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(ext)
                do {
                    try data.write(to: url)
                    continuation.resume(returning: url)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
