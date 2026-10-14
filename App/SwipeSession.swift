import Photos
import SwiftUI
import WidgetKit

/// Identifies which category a `SwipeSession` is browsing, and derives its persistence key.
enum SessionKind: Hashable {
    case onThisDay(Date)
    case recents
    case random(Date)
    case month(Date)
    case bookmarked
    case duplicates

    var storageKey: String {
        switch self {
        case .onThisDay(let date): return "onThisDay-\(Self.dayFormatter.string(from: date))"
        case .recents: return "recents"
        case .random(let date): return "random-\(Self.dayFormatter.string(from: date))"
        case .month(let date): return "month-\(Self.monthFormatter.string(from: date))"
        case .bookmarked: return "bookmarked"
        case .duplicates: return "duplicates"
        }
    }

    var title: String {
        switch self {
        case .onThisDay: return "On This Day"
        case .recents: return "Recents"
        case .random: return "Random"
        case .month(let date): return Self.monthTitleFormatter.string(from: date).uppercased()
        case .bookmarked: return "Bookmarked"
        case .duplicates: return "Duplicates"
        }
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"; return f
    }()
    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM ''yy"; return f
    }()
}

@MainActor
final class SwipeSession: ObservableObject {
    enum Decision: String, Codable { case keep, delete }
    struct Swipe { let asset: PHAsset; var decision: Decision }

    @Published private(set) var kind: SessionKind
    @Published var authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published private(set) var assets: [PHAsset] = []
    @Published private(set) var history: [Swipe] = []
    @Published private(set) var isLoading = false
    @Published private(set) var deletedCount = 0
    @Published private(set) var freedBytes: Int64 = 0
    @Published private(set) var freedBytesUnavailable = false

    /// Photos you swiped right on stay hidden on later visits to On This Day unless "Show photos I kept" is on.
    private nonisolated static let keptKey = "keptAssetIDs"
    private nonisolated static let bookmarkedKey = "bookmarkedAssetIDs"
    private nonisolated static let showKeptKey = "showKept"

    nonisolated static var showKept: Bool {
        get { UserDefaults.standard.bool(forKey: showKeptKey) }
        set { UserDefaults.standard.set(newValue, forKey: showKeptKey) }
    }

    private nonisolated static let monthsNewestFirstKey = "monthsNewestFirst"
    nonisolated static var monthsNewestFirst: Bool {
        get { UserDefaults.standard.object(forKey: monthsNewestFirstKey) == nil ? true : UserDefaults.standard.bool(forKey: monthsNewestFirstKey) }
        set { UserDefaults.standard.set(newValue, forKey: monthsNewestFirstKey) }
    }

    nonisolated static var bookmarked: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: bookmarkedKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: bookmarkedKey) }
    }

    /// Exposed statically (not just as a private instance accessor) so `HomeView` can compute On This Day's
    /// row count with the same filtering `SwipeSession` itself applies.
    nonisolated static var kept: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: keptKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: keptKey) }
    }

    /// Cumulative space freed across every session ever, shown on the summary screen's "saved all-time" line.
    private nonisolated static let allTimeFreedBytesKey = "allTimeFreedBytes"
    nonisolated static var allTimeFreedBytes: Int64 {
        get { Int64(UserDefaults.standard.integer(forKey: allTimeFreedBytesKey)) }
        set { UserDefaults.standard.set(Int(newValue), forKey: allTimeFreedBytesKey) }
    }

    init(kind: SessionKind) { self.kind = kind }

    /// Convenience accessor for date-parametrized kinds, e.g. for a two-way `DatePicker` binding.
    var date: Date {
        get {
            switch kind {
            case .onThisDay(let date): return date
            case .random(let date): return date
            case .recents, .month, .bookmarked, .duplicates: return .now
            }
        }
        set { changeDate(to: newValue) }
    }

    var current: PHAsset? { history.count < assets.count ? assets[history.count] : nil }
    var next: PHAsset? { history.count + 1 < assets.count ? assets[history.count + 1] : nil }
    var remaining: Int { assets.count - history.count }
    var marked: [PHAsset] { history.filter { $0.decision == .delete }.map(\.asset) }
    var keptCount: Int { history.filter { $0.decision == .keep }.count }
    var hasAccess: Bool { authorization == .authorized || authorization == .limited }
    var isFinished: Bool { !isLoading && !assets.isEmpty && history.count == assets.count }

    func start() async {
        if authorization == .notDetermined {
            authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        if hasAccess { reload() }
    }

    /// Only meaningful for date-parametrized kinds; swaps in a new date and reloads under that date's own storage key.
    func changeDate(to date: Date) {
        switch kind {
        case .onThisDay: kind = .onThisDay(date)
        case .random: kind = .random(date)
        default: return
        }
        reload()
    }

    func reload() {
        isLoading = true
        history = []
        Task { await performReload() }
    }

    /// Like `reload()`, but awaitable so a caller can inspect `assets` right after it settles.
    func reloadAndWait() async {
        isLoading = true
        history = []
        await performReload()
    }

    private func performReload() async {
        let kind = self.kind
        let saved = Self.loadPersisted(for: kind.storageKey)
        let found = await Task.detached(priority: .userInitiated) { Self.query(for: kind) }.value
        apply(found: found, saved: saved)
        isLoading = false
    }

    private func apply(found: [PHAsset], saved: PersistedState?) {
        var live = found
        if case .onThisDay = kind, !Self.showKept {
            let kept = Self.kept
            live = live.filter { !kept.contains($0.localIdentifier) }
        }
        guard let saved, !saved.queueIdentifiers.isEmpty else {
            assets = live
            history = []
            return
        }
        let liveByID = Dictionary(uniqueKeysWithValues: live.map { ($0.localIdentifier, $0) })
        var orderedAssets: [PHAsset] = []
        var orderedHistory: [Swipe] = []
        for id in saved.queueIdentifiers {
            guard let asset = liveByID[id] else { continue } // deleted outside the app, or newly filtered out
            orderedAssets.append(asset)
            if let decision = saved.decisions[id] {
                orderedHistory.append(Swipe(asset: asset, decision: decision))
            }
        }
        assets = orderedAssets
        history = orderedHistory
    }

    func decide(_ decision: Decision) {
        guard let asset = current else { return }
        history.append(Swipe(asset: asset, decision: decision))
        if decision == .keep { addKept(asset.localIdentifier) }
        persist()
    }

    func undo() {
        guard let last = history.popLast() else { return }
        if last.decision == .keep { removeKept(last.asset.localIdentifier) }
        persist()
    }

    func unmark(_ asset: PHAsset) {
        guard let i = history.firstIndex(where: { $0.asset.localIdentifier == asset.localIdentifier }) else { return }
        history[i].decision = .keep
        addKept(asset.localIdentifier)
        persist()
    }

    /// Opposite of `unmark`: moves a kept-but-undecided-delete asset back to delete-marked, from the review grid.
    func remark(_ asset: PHAsset) {
        guard let i = history.firstIndex(where: { $0.asset.localIdentifier == asset.localIdentifier }) else { return }
        history[i].decision = .delete
        removeKept(asset.localIdentifier)
        persist()
    }

    private func addKept(_ id: String) {
        var set = Self.kept; set.insert(id); Self.kept = set
    }

    private func removeKept(_ id: String) {
        var set = Self.kept; set.remove(id); Self.kept = set
    }

    func isBookmarked(_ asset: PHAsset) -> Bool { Self.bookmarked.contains(asset.localIdentifier) }

    func toggleBookmark(_ asset: PHAsset) {
        var set = Self.bookmarked
        if set.contains(asset.localIdentifier) { set.remove(asset.localIdentifier) } else { set.insert(asset.localIdentifier) }
        Self.bookmarked = set
    }

    /// iOS shows its own "Allow to delete N photos?" prompt. Deleted items go to Recently Deleted for 30 days.
    func deleteMarked() async -> Bool {
        let targets = marked
        guard !targets.isEmpty else { return true }
        // KTD6: capture each asset's real size immediately before the delete call — PHAssetResource's
        // fileSize is undocumented KVC, not public API, and reads 0 if a future iOS removes/renames it.
        let batchFreed = Self.totalFileSize(for: targets)
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(targets as NSArray)
            }
            let ids = Set(targets.map(\.localIdentifier))
            assets.removeAll { ids.contains($0.localIdentifier) }
            history.removeAll { ids.contains($0.asset.localIdentifier) }
            var bookmarks = Self.bookmarked
            bookmarks.subtract(ids)
            Self.bookmarked = bookmarks
            deletedCount += targets.count
            if batchFreed > 0 {
                freedBytes += batchFreed
                Self.allTimeFreedBytes += batchFreed
            } else {
                freedBytesUnavailable = true
            }
            persist()
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            return false // user tapped Don't Allow, or the change failed
        }
    }

    private nonisolated static func totalFileSize(for assets: [PHAsset]) -> Int64 {
        assets.reduce(Int64(0)) { total, asset in
            let resources = PHAssetResource.assetResources(for: asset)
            let size = (resources.first?.value(forKey: "fileSize") as? Int64) ?? 0
            return total + size
        }
    }

    private func persist() {
        let state = PersistedState(
            queueIdentifiers: assets.map(\.localIdentifier),
            decisions: Dictionary(uniqueKeysWithValues: history.map { ($0.asset.localIdentifier, $0.decision) })
        )
        Self.savePersisted(state, for: kind.storageKey)
    }

    private struct PersistedState: Codable {
        var queueIdentifiers: [String]
        var decisions: [String: Decision]
    }

    private static func loadPersisted(for key: String) -> PersistedState? {
        guard let data = UserDefaults.standard.data(forKey: "session-\(key)") else { return nil }
        return try? JSONDecoder().decode(PersistedState.self, from: data)
    }

    private static func savePersisted(_ state: PersistedState, for key: String) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: "session-\(key)")
    }

    private nonisolated static func query(for kind: SessionKind) -> [PHAsset] {
        switch kind {
        case .onThisDay(let date): return OnThisDayQuery.assets(on: date)
        case .recents: return LibraryQueries.recents()
        case .random(let date): return LibraryQueries.random(day: date)
        case .month(let date): return LibraryQueries.month(date)
        case .bookmarked:
            return LibraryQueries.assets(forIdentifiers: Array(bookmarked))
                .sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        case .duplicates: return LibraryQueries.duplicates()
        }
    }
}
