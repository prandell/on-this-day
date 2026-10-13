import Photos
import SwiftUI

struct HomeView: View {
    @Binding var path: [SessionKind]
    @State private var authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var rows: [Row] = []
    @State private var showKept = SwipeSession.showKept
    @State private var showMenu = false

    private struct Row: Identifiable {
        let id: String
        let kind: SessionKind
        let count: Int
        let isMonth: Bool
    }

    private var hasAccess: Bool { authorization == .authorized || authorization == .limited }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                Group {
                    if hasAccess {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                                    Button { path.append(row.kind) } label: {
                                        rowContent(row, index: index)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else if authorization == .notDetermined {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else {
                        Spacer()
                        deniedView
                        Spacer()
                    }
                }
                .background(Theme.background)
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SessionKind.self) { kind in
                SwipeSessionView(kind: kind)
            }
        }
        .preferredColorScheme(.dark)
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

    private var header: some View {
        HStack {
            Text("On This Day")
                .font(.system(.title, design: .rounded).weight(.heavy).italic())
                .foregroundStyle(.black)
            Spacer()
            Button { showMenu = true } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.7))
            }
            .confirmationDialog("Options", isPresented: $showMenu, titleVisibility: .hidden) {
                Button(showKept ? "Hide photos I kept" : "Show photos I kept") { showKept.toggle() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.94, green: 0.80, blue: 0.70))
    }

    private func rowContent(_ row: Row, index: Int) -> some View {
        HStack {
            Text(row.isMonth ? row.kind.title : row.kind.title.lowercased())
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
            rowIcon(row)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .foregroundStyle(row.isMonth ? Theme.monthRowColors[index % Theme.monthRowColors.count].text : .white)
        .background(rowBackground(row, index: index))
    }

    @ViewBuilder
    private func rowBackground(_ row: Row, index: Int) -> some View {
        if row.isMonth {
            Theme.monthRowColors[index % Theme.monthRowColors.count].background
        } else {
            categoryGradient(for: row.kind)
        }
    }

    private func categoryGradient(for kind: SessionKind) -> LinearGradient {
        switch kind {
        case .onThisDay: return Theme.categoryGradients[0]
        case .recents: return Theme.categoryGradients[1]
        case .random: return Theme.categoryGradients[2]
        case .bookmarked: return Theme.categoryGradients[3]
        case .month: return Theme.categoryGradients[0]
        }
    }

    @ViewBuilder
    private func rowIcon(_ row: Row) -> some View {
        switch row.kind {
        case .onThisDay:
            EmptyView()
        case .recents:
            ZStack(alignment: .topTrailing) {
                Image(systemName: "clock.fill")
                    .font(.title)
                    .foregroundStyle(Color.blue.opacity(0.8))
                    .padding(10)
                    .background(Circle().fill(.white))
                if row.count > 0 {
                    Text("\(min(row.count, 99))")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Circle().fill(.red))
                        .offset(x: 4, y: -4)
                }
            }
        case .random:
            Image(systemName: "shuffle")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        case .bookmarked:
            Image(systemName: "bookmark.fill")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        case .month:
            EmptyView()
        }
    }

    private func loadRows() async {
        rows = await Task.detached(priority: .userInitiated) { Self.computeRows() }.value
    }

    private nonisolated static func computeRows() -> [Row] {
        let onThisDayAll = OnThisDayQuery.assets(on: .now)
        let kept = SwipeSession.kept
        let onThisDayVisible = SwipeSession.showKept ? onThisDayAll : onThisDayAll.filter { !kept.contains($0.localIdentifier) }

        var rows: [Row] = [
            Row(id: "onThisDay", kind: .onThisDay(.now), count: onThisDayVisible.count, isMonth: false),
            Row(id: "recents", kind: .recents, count: LibraryQueries.recents().count, isMonth: false),
            Row(id: "random", kind: .random(.now), count: LibraryQueries.random(day: .now).count, isMonth: false),
            Row(id: "bookmarked", kind: .bookmarked, count: LibraryQueries.assets(forIdentifiers: Array(SwipeSession.bookmarked)).count, isMonth: false),
        ]
        for month in LibraryQueries.monthsWithPhotos() {
            rows.append(Row(id: "month-\(month.timeIntervalSince1970)", kind: .month(month), count: LibraryQueries.month(month).count, isMonth: true))
        }
        return rows
    }

    private var deniedView: some View {
        ContentUnavailableView {
            Label("Photos access needed", systemImage: "photo.on.rectangle.angled")
                .foregroundStyle(.white)
        } description: {
            Text("Allow full access to Photos in Settings so the app can find and delete photos.")
                .foregroundStyle(.white.opacity(0.7))
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
        }
    }
}
