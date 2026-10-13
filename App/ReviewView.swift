import Photos
import SwiftUI

struct ReviewView: View {
    @ObservedObject var deck: SwipeSession
    @Environment(\.dismiss) private var dismiss
    @State private var deleting = false
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 4)]

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Tap a photo to keep it. Deleted photos sit in Recently Deleted for 30 days, and the deletion syncs to iCloud and your other devices.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(deck.marked, id: \.localIdentifier) { asset in
                        AssetImage(asset: asset, isFrontCard: false)
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()
                            .onTapGesture { withAnimation { deck.unmark(asset) } }
                    }
                }
            }
            .navigationTitle("\(deck.marked.count) to delete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Delete", role: .destructive) {
                        deleting = true
                        Task {
                            let ok = await deck.deleteMarked()
                            deleting = false
                            if ok { dismiss() }
                        }
                    }
                    .disabled(deck.marked.isEmpty || deleting)
                }
            }
        }
    }
}
