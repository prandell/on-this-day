import Photos
import SwiftUI

struct ReviewView: View {
    @ObservedObject var deck: SwipeSession
    @Environment(\.dismiss) private var dismiss
    @State private var deleting = false
    private let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]

    private var kept: [PHAsset] { deck.history.filter { $0.decision == .keep }.map(\.asset) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        section(title: "DELETE", symbol: "trash.fill", tint: Theme.deleteColor, assets: deck.marked) { asset in
                            withAnimation { deck.unmark(asset) }
                        }
                        section(title: "KEEP", symbol: "checkmark", tint: Theme.keepColor, assets: kept) { asset in
                            withAnimation { deck.remark(asset) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }

            VStack {
                Spacer()
                Button {
                    deleting = true
                    Task {
                        let ok = await deck.deleteMarked()
                        deleting = false
                        if ok { dismiss() }
                    }
                } label: {
                    Label("Delete \(deck.marked.count) Images", systemImage: "trash.fill")
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.deleteColor.opacity(0.9), in: Capsule())
                }
                .disabled(deck.marked.isEmpty || deleting)
                .opacity(deck.marked.isEmpty ? 0.4 : 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            Text(deck.kind.title.uppercased())
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
            Text("\(deck.history.count)/\(deck.assets.count) · \(progressPercent)%")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var progressPercent: Int {
        guard deck.assets.count > 0 else { return 0 }
        return Int((Double(deck.history.count) / Double(deck.assets.count) * 100).rounded())
    }

    private func section(title: String, symbol: String, tint: Color, assets: [PHAsset], onTap: @escaping (PHAsset) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    AssetImage(asset: asset, isFrontCard: false)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .onTapGesture { onTap(asset) }
                }
            }
        }
    }
}
