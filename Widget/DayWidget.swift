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
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            Text(entry.date.formatted(.dateTime.day().month(.abbreviated)).uppercased())
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
            Text(headline)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .containerBackground(for: .widget) {
            ZStack {
                if let image = entry.image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [Color(red: 0.31, green: 0.24, blue: 0.88), Color(red: 0.70, green: 0.31, blue: 0.88)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.1), location: 0.45),
                        .init(color: .black.opacity(0.82), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
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
