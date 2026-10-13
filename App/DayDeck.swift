import Photos
import SwiftUI
import WidgetKit

@MainActor
final class DayDeck: ObservableObject {
    enum Decision { case keep, delete }
    struct Swipe { let asset: PHAsset; var decision: Decision }

    @Published var authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published var date = Date.now
    @Published var showKept = false
    @Published private(set) var assets: [PHAsset] = []
    @Published private(set) var history: [Swipe] = []
    @Published private(set) var isLoading = false

    /// Photos you swiped right on stay hidden on later days unless "Show photos I kept" is on.
    private let keptKey = "keptAssetIDs"
    private var kept: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: keptKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: keptKey) }
    }

    var current: PHAsset? { history.count < assets.count ? assets[history.count] : nil }
    var next: PHAsset? { history.count + 1 < assets.count ? assets[history.count + 1] : nil }
    var remaining: Int { assets.count - history.count }
    var marked: [PHAsset] { history.filter { $0.decision == .delete }.map(\.asset) }
    var hasAccess: Bool { authorization == .authorized || authorization == .limited }

    func start() async {
        if authorization == .notDetermined {
            authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        if hasAccess { reload() }
    }

    func reload() {
        isLoading = true
        history = []
        let date = self.date, showKept = self.showKept, kept = self.kept
        Task {
            let found = await Task.detached(priority: .userInitiated) { OnThisDayQuery.assets(on: date) }.value
            assets = showKept ? found : found.filter { !kept.contains($0.localIdentifier) }
            isLoading = false
        }
    }

    func decide(_ decision: Decision) {
        guard let asset = current else { return }
        history.append(Swipe(asset: asset, decision: decision))
        if decision == .keep { kept.insert(asset.localIdentifier) }
    }

    func undo() {
        guard let last = history.popLast() else { return }
        if last.decision == .keep { kept.remove(last.asset.localIdentifier) }
    }

    func unmark(_ asset: PHAsset) {
        guard let i = history.firstIndex(where: { $0.asset.localIdentifier == asset.localIdentifier }) else { return }
        history[i].decision = .keep
        kept.insert(asset.localIdentifier)
    }

    /// iOS shows its own "Allow to delete N photos?" prompt. Deleted items go to Recently Deleted for 30 days.
    func deleteMarked() async -> Bool {
        let targets = marked
        guard !targets.isEmpty else { return true }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(targets as NSArray)
            }
            let ids = Set(targets.map(\.localIdentifier))
            assets.removeAll { ids.contains($0.localIdentifier) }
            history.removeAll { ids.contains($0.asset.localIdentifier) }
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            return false // user tapped Don't Allow, or the change failed
        }
    }
}
