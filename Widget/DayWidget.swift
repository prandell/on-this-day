import SwiftUI
import WidgetKit

struct DayEntry: TimelineEntry {
    let date: Date
}

struct DayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(DayEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        completion(Timeline(entries: [DayEntry(date: .now)], policy: .never))
    }
}

struct DayWidgetView: View {
    var body: some View {
        SausageArtwork()
            .aspectRatio(320.0 / 140.0, contentMode: .fit)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                SausageArtwork.background
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Sausage")
            .accessibilityHint("Opens the spinning sausage.")
            .widgetURL(URL(string: "onthisday://today"))
    }
}

@main
struct DayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OnThisDay", provider: DayProvider()) { _ in
            DayWidgetView()
        }
        .configurationDisplayName("Sausage")
        .description("A sausage. Tap to watch it spin.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
