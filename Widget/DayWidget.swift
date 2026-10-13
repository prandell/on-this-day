import Photos
import SwiftUI
import WidgetKit

struct DayEntry: TimelineEntry {
    let date: Date
    let count: Int
    let image: UIImage?
    let hasAccess: Bool
}

struct DayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: .now, count: 12, image: nil, hasAccess: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now)
        completion(Timeline(entries: [makeEntry()], policy: .after(tomorrow)))
    }

    private func makeEntry() -> DayEntry {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            return DayEntry(date: .now, count: 0, image: nil, hasAccess: false)
        }
        let assets = OnThisDayQuery.assets(on: .now)
        let cover = assets.first(where: { $0.mediaType == .image }).flatMap(thumbnail)
        return DayEntry(date: .now, count: assets.count, image: cover, hasAccess: true)
    }

    private func thumbnail(_ asset: PHAsset) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        var result: UIImage?
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 500, height: 500),
                                              contentMode: .aspectFill, options: options) { image, _ in result = image }
        return result
    }
}

struct DayWidgetView: View {
    let entry: DayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Spacer()
            Text(entry.date.formatted(.dateTime.day().month(.abbreviated)).uppercased())
                .font(.caption2.weight(.semibold))
            Text(headline)
                .font(.headline)
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .shadow(radius: 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            if let image = entry.image {
                Image(uiImage: image).resizable().scaledToFill()
                    .overlay(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom))
            } else {
                LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .widgetURL(URL(string: "onthisday://today"))
    }

    private var headline: String {
        guard entry.hasAccess else { return "Open to allow Photos" }
        switch entry.count {
        case 0: return "Nothing today"
        case 1: return "1 to review"
        default: return "\(entry.count) to review"
        }
    }
}

@main
struct DayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OnThisDay", provider: DayProvider()) { entry in
            DayWidgetView(entry: entry)
        }
        .configurationDisplayName("On This Day")
        .description("Photos from this date in past years.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
