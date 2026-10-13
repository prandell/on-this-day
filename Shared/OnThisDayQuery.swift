import Foundation
import Photos

/// Finds photos and videos taken on a given month/day in every earlier year.
enum OnThisDayQuery {
    /// Newest year first, oldest photo first within each year.
    static func assets(on date: Date = .now, calendar: Calendar = .current) -> [PHAsset] {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard let thisYear = parts.year, let month = parts.month, let day = parts.day,
              let firstYear = earliestYear(calendar: calendar), firstYear < thisYear else { return [] }

        var results: [PHAsset] = []
        for year in stride(from: thisYear - 1, through: firstYear, by: -1) {
            guard let start = calendar.date(from: DateComponents(year: year, month: month, day: day)),
                  calendar.component(.day, from: start) == day, // skips 29 Feb in non-leap years
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }

            let options = PHFetchOptions()
            options.predicate = NSPredicate(
                format: "creationDate >= %@ AND creationDate < %@ AND (mediaType == %@ OR mediaType == %@)",
                start as NSDate, end as NSDate,
                NSNumber(value: PHAssetMediaType.image.rawValue),
                NSNumber(value: PHAssetMediaType.video.rawValue)
            )
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            PHAsset.fetchAssets(with: options).enumerateObjects { asset, _, _ in results.append(asset) }
        }
        return results
    }

    private static func earliestYear(calendar: Calendar) -> Int? {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.fetchLimit = 1
        guard let date = PHAsset.fetchAssets(with: options).firstObject?.creationDate else { return nil }
        return calendar.component(.year, from: date)
    }
}
