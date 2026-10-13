import Foundation
import Photos

/// Queries backing every `SessionKind` other than `.onThisDay`, which keeps using `OnThisDayQuery`.
enum LibraryQueries {
    /// Most recent photos/videos by creation date, newest first.
    static func recents(limit: Int = 50) -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = mediaTypePredicate
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit
        var results: [PHAsset] = []
        PHAsset.fetchAssets(with: options).enumerateObjects { asset, _, _ in results.append(asset) }
        return results
    }

    /// A batch of randomly-chosen photos/videos, seeded by `day` so the same day always reproduces the same batch.
    static func random(day: Date, calendar: Calendar = .current, batchSize: Int = 30) -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = mediaTypePredicate
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let all = PHAsset.fetchAssets(with: options)
        guard all.count > 0 else { return [] }

        let seed = calendar.dateComponents([.year, .month, .day], from: day)
        var generator = SeededGenerator(seed: UInt64((seed.year ?? 0) * 10_000 + (seed.month ?? 0) * 100 + (seed.day ?? 0)))
        let indices = (0..<all.count).shuffled(using: &generator).prefix(batchSize)
        return indices.map { all.object(at: $0) }
    }

    /// Photos/videos created within the given calendar month, newest first.
    static func month(_ monthStart: Date, calendar: Calendar = .current) -> [PHAsset] {
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return [] }
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate < %@ AND (mediaType == %@ OR mediaType == %@)",
            monthStart as NSDate, monthEnd as NSDate,
            NSNumber(value: PHAssetMediaType.image.rawValue),
            NSNumber(value: PHAssetMediaType.video.rawValue)
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        var results: [PHAsset] = []
        PHAsset.fetchAssets(with: options).enumerateObjects { asset, _, _ in results.append(asset) }
        return results
    }

    /// Every month (first-of-month date) that has at least one photo/video, newest first.
    static func monthsWithPhotos(calendar: Calendar = .current) -> [Date] {
        let options = PHFetchOptions()
        options.predicate = mediaTypePredicate
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let all = PHAsset.fetchAssets(with: options)
        var seen = Set<DateComponents>()
        var months: [Date] = []
        all.enumerateObjects { asset, _, _ in
            guard let created = asset.creationDate else { return }
            let parts = calendar.dateComponents([.year, .month], from: created)
            guard seen.insert(parts).inserted, let start = calendar.date(from: parts) else { return }
            months.append(start)
        }
        return months
    }

    /// Fetches assets by local identifier, preserving no particular order (callers sort as needed).
    static func assets(forIdentifiers identifiers: [String]) -> [PHAsset] {
        guard !identifiers.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    private static var mediaTypePredicate: NSPredicate {
        NSPredicate(format: "mediaType == %@ OR mediaType == %@",
                    NSNumber(value: PHAssetMediaType.image.rawValue),
                    NSNumber(value: PHAssetMediaType.video.rawValue))
    }
}

/// A deterministic, seedable random source so `LibraryQueries.random` reproduces the same shuffle for the same day.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xdead_beef : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
