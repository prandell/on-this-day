import Photos
import SwiftUI

struct SwipeSessionView: View {
    let kind: SessionKind
    @StateObject private var deck: SwipeSession
    @State private var showReview = false
    @State private var shareURL: ShareURL?
    @State private var favoriteOverrides: [String: Bool] = [:]
    @State private var sessionResult: SessionResult?
    @Environment(\.dismiss) private var dismiss

    init(kind: SessionKind) {
        self.kind = kind
        _deck = StateObject(wrappedValue: SwipeSession(kind: kind))
    }

    var body: some View {
        Group {
            if deck.hasAccess { deckView }
            else if deck.authorization == .notDetermined { ProgressView() }
            else { deniedView }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .onThisDay = kind {
                ToolbarItem(placement: .topBarLeading) {
                    DatePicker("Date", selection: $deck.date, displayedComponents: .date).labelsHidden()
                }
            }
        }
        .sheet(isPresented: $showReview) { ReviewView(deck: deck) }
        .sheet(item: $shareURL) { item in ShareSheet(items: [item.url]) }
        .fullScreenCover(item: $sessionResult) { result in
            SessionSummaryView(result: result, categoryTitle: kind.title, onBackToCategory: backToCategory, onReturnHome: returnHome)
        }
        .task { await deck.start() }
        .onChange(of: deck.history.count) { checkCompletion() }
    }

    /// R7: once the queue is exhausted *and* any pending deletions have been confirmed via Review, show the summary.
    private func checkCompletion() {
        guard deck.isFinished, deck.marked.isEmpty, sessionResult == nil else { return }
        sessionResult = SessionResult(
            keptCount: deck.keptCount,
            deletedCount: deck.deletedCount,
            freedBytes: deck.freedBytesUnavailable ? nil : deck.freedBytes
        )
    }

    private func backToCategory() {
        sessionResult = nil
        Task {
            await deck.reloadAndWait()
            if deck.assets.isEmpty { dismiss() }
        }
    }

    private func returnHome() {
        sessionResult = nil
        dismiss()
    }

    private var deckView: some View {
        VStack(spacing: 16) {
            if deck.isLoading {
                Spacer(); ProgressView("Finding photos…"); Spacer()
            } else if let asset = deck.current {
                Text("\(deck.remaining) left").font(.subheadline).foregroundStyle(.secondary)
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        if let next = deck.next {
                            AssetImage(asset: next, isFrontCard: false)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .scaleEffect(0.94)
                                .opacity(0.5)
                        }
                        SwipeCard(asset: asset) { decision in
                            withAnimation { deck.decide(decision) }
                        }
                        .id(asset.localIdentifier)
                    }
                    actionStack(for: asset)
                }
                .padding(.horizontal)
                controls
            } else {
                Spacer()
                ContentUnavailableView(
                    deck.assets.isEmpty ? "Nothing here" : "All done",
                    systemImage: deck.assets.isEmpty ? "photo.on.rectangle" : "checkmark.circle",
                    description: Text(deck.assets.isEmpty ? "No photos found for this category." : "You've been through everything.")
                )
                Spacer()
            }

            if !deck.marked.isEmpty {
                Button { showReview = true } label: {
                    Label("Review \(deck.marked.count) to delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private func actionStack(for asset: PHAsset) -> some View {
        VStack(spacing: 20) {
            actionButton(isFavorite(asset) ? "heart.fill" : "heart", tint: .pink) {
                toggleFavorite(asset)
            }
            actionButton("square.and.arrow.up", tint: .blue) {
                share(asset)
            }
            actionButton(deck.isBookmarked(asset) ? "bookmark.fill" : "bookmark", tint: .orange) {
                deck.toggleBookmark(asset)
            }
        }
    }

    private func actionButton(_ symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(.secondarySystemBackground)))
        }
    }

    private func isFavorite(_ asset: PHAsset) -> Bool {
        favoriteOverrides[asset.localIdentifier] ?? asset.isFavorite
    }

    private func toggleFavorite(_ asset: PHAsset) {
        let newValue = !isFavorite(asset)
        favoriteOverrides[asset.localIdentifier] = newValue
        Task {
            try? await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest(for: asset).isFavorite = newValue
            }
        }
    }

    private func share(_ asset: PHAsset) {
        Task {
            if let url = await ShareItemLoader.url(for: asset) {
                shareURL = ShareURL(url: url)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 36) {
            roundButton("xmark", .red) { withAnimation { deck.decide(.delete) } }
            roundButton("arrow.uturn.backward", .gray) { withAnimation { deck.undo() } }
                .disabled(deck.history.isEmpty)
            roundButton("heart.fill", .green) { withAnimation { deck.decide(.keep) } }
        }
    }

    private func roundButton(_ symbol: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color(.secondarySystemBackground)))
        }
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

private struct ShareURL: Identifiable {
    let id = UUID()
    let url: URL
}
