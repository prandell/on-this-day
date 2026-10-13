import Photos
import SwiftUI

struct HomeView: View {
    @Binding var path: [SessionKind]
    @State private var authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var rows: [Row] = []
    @State private var isLoading = true
    @State private var showKept = SwipeSession.showKept

    private struct Row: Identifiable {
        let id: String
        let kind: SessionKind
        let count: Int
    }

    private var hasAccess: Bool { authorization == .authorized || authorization == .limited }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if hasAccess {
                    List(rows) { row in
                        NavigationLink(value: row.kind) {
                            HStack {
                                Text(row.kind.title)
                                Spacer()
                                Text("\(row.count)").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .overlay { if isLoading { ProgressView() } }
                } else if authorization == .notDetermined {
                    ProgressView()
                } else {
                    deniedView
                }
            }
            .navigationTitle("On This Day")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle("Show photos I kept", isOn: $showKept)
                }
            }
            .navigationDestination(for: SessionKind.self) { kind in
                SwipeSessionView(kind: kind)
            }
        }
        .task {
            if authorization == .notDetermined {
                authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            }
            if hasAccess { await loadRows() }
        }
        .onChange(of: showKept) {
            SwipeSession.showKept = showKept
            if hasAccess { Task { await loadRows() } }
        }
    }

    private func loadRows() async {
        isLoading = true
        rows = await Task.detached(priority: .userInitiated) { Self.computeRows() }.value
        isLoading = false
    }

    private static func computeRows() -> [Row] {
        let onThisDayAll = OnThisDayQuery.assets(on: .now)
        let kept = SwipeSession.kept
        let onThisDayVisible = SwipeSession.showKept ? onThisDayAll : onThisDayAll.filter { !kept.contains($0.localIdentifier) }

        var rows: [Row] = [
            Row(id: "onThisDay", kind: .onThisDay(.now), count: onThisDayVisible.count),
            Row(id: "recents", kind: .recents, count: LibraryQueries.recents().count),
            Row(id: "random", kind: .random(.now), count: LibraryQueries.random(day: .now).count),
            Row(id: "bookmarked", kind: .bookmarked, count: LibraryQueries.assets(forIdentifiers: Array(SwipeSession.bookmarked)).count),
        ]
        for month in LibraryQueries.monthsWithPhotos() {
            rows.append(Row(id: "month-\(month.timeIntervalSince1970)", kind: .month(month), count: LibraryQueries.month(month).count))
        }
        return rows
    }

    private var deniedView: some View {
        ContentUnavailableView {
            Label("Photos access needed", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Allow full access to Photos in Settings so the app can find and delete photos.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
        }
    }
}
