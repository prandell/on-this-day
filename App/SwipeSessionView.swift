import Photos
import SwiftUI

struct SwipeSessionView: View {
    let kind: SessionKind
    @StateObject private var deck: SwipeSession
    @State private var showReview = false
    @State private var showDatePicker = false
    @State private var shareURL: ShareURL?
    @State private var favoriteOverrides: [String: Bool] = [:]
    @State private var sessionResult: SessionResult?
    @State private var dragAmount: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    init(kind: SessionKind) {
        self.kind = kind
        _deck = StateObject(wrappedValue: SwipeSession(kind: kind))
    }

    var body: some View {
        ZStack {
            backgroundTint.ignoresSafeArea()
            Group {
                if deck.hasAccess { deckView }
                else if deck.authorization == .notDetermined { ProgressView().tint(.white) }
                else { deniedView }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showReview) { ReviewView(deck: deck) }
        .sheet(item: $shareURL) { item in ShareSheet(items: [item.url]) }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .fullScreenCover(item: $sessionResult) { result in
            SessionSummaryView(result: result, categoryTitle: kind.title, onBackToCategory: backToCategory, onReturnHome: returnHome)
        }
        .task { await deck.start() }
        .onChange(of: deck.history.count) { checkCompletion() }
        .preferredColorScheme(.dark)
    }

    private var backgroundTint: Color {
        if dragAmount > 0 { return Theme.keepColor.opacity(Double(dragAmount) * 0.3) }
        if dragAmount < 0 { return Theme.deleteColor.opacity(Double(-dragAmount) * 0.3) }
        return Theme.background
    }

    /// R7: once the queue is exhausted *and* any pending deletions have been confirmed via Review, show the summary.
    private func checkCompletion() {
        guard deck.isFinished, deck.marked.isEmpty, sessionResult == nil else { return }
        sessionResult = SessionResult(
            keptCount: deck.keptCount,
            deletedCount: deck.deletedCount,
            freedBytes: deck.freedBytesUnavailable ? nil : deck.freedBytes,
            allTimeFreedBytes: SwipeSession.allTimeFreedBytes
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
        VStack(spacing: 0) {
            header
            if deck.isLoading {
                Spacer(); ProgressView().tint(.white); Spacer()
            } else if let asset = deck.current {
                ZStack {
                    if let next = deck.next {
                        AssetImage(asset: next, isFrontCard: false)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .scaleEffect(0.94)
                            .opacity(0.5)
                            .padding(.horizontal, 2)
                    }
                    SwipeCard(asset: asset, onDecide: { decision in withAnimation { deck.decide(decision) } }, dragAmount: $dragAmount)
                        .id(asset.localIdentifier)
                    actionStack(for: asset)
                }
                .padding(.horizontal, 2)
                Spacer(minLength: 12)
                keepDeleteRow
                if !deck.marked.isEmpty {
                    Button { showReview = true } label: {
                        Label("Review \(deck.marked.count)", systemImage: "trash")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 10)
                }
                Spacer(minLength: 16)
            } else {
                Spacer()
                ContentUnavailableView(
                    deck.assets.isEmpty ? "Nothing here" : "All done",
                    systemImage: deck.assets.isEmpty ? "photo.on.rectangle" : "checkmark.circle",
                    description: Text(deck.assets.isEmpty ? "No photos found for this category." : "You've been through everything.")
                )
                .foregroundStyle(.white)
                Spacer()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.12)))
                }
                Spacer()
                if case .onThisDay = kind {
                    Button { showDatePicker = true } label: {
                        Text(headerDateText)
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                Button { deck.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.body.weight(.bold))
                        .foregroundStyle(deck.history.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.12)))
                }
                .disabled(deck.history.isEmpty)
            }
            Text(progressText)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var headerDateText: String {
        deck.date.formatted(.dateTime.month(.abbreviated).day()).uppercased()
    }

    private var progressText: String {
        let total = deck.assets.count
        guard total > 0 else { return "" }
        let done = deck.history.count
        let percent = Int((Double(done) / Double(total) * 100).rounded())
        return "\(done)/\(total) · \(percent)%"
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("Date", selection: Binding(get: { deck.date }, set: { deck.date = $0 }), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Choose a date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { showDatePicker = false } }
                }
        }
        .presentationDetents([.medium])
    }

    private var keepDeleteRow: some View {
        HStack {
            Button { withAnimation { deck.decide(.delete) } } label: {
                Text("DELETE")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.deleteColor.opacity(dragAmount < 0 ? 1 : 0.55))
            }
            Spacer()
            Button { withAnimation { deck.decide(.keep) } } label: {
                Text("KEEP")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.keepColor.opacity(dragAmount > 0 ? 1 : 0.55))
            }
        }
        .padding(.horizontal, 28)
    }

    private func actionStack(for asset: PHAsset) -> some View {
        VStack(spacing: 22) {
            actionButton(isFavorite(asset) ? "heart.fill" : "heart") { toggleFavorite(asset) }
            actionButton(deck.isBookmarked(asset) ? "bookmark.fill" : "bookmark") { deck.toggleBookmark(asset) }
            actionButton("square.and.arrow.up") { share(asset) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.trailing, 20)
    }

    private func actionButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 4)
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

private struct ShareURL: Identifiable {
    let id = UUID()
    let url: URL
}
