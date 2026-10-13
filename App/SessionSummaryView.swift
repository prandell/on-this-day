import SwiftUI

struct SessionResult: Identifiable {
    let id = UUID()
    let keptCount: Int
    let deletedCount: Int
    /// `nil` means KTD6's file-size lookup came back empty for real deletions — show "unavailable", not a false "0 MB".
    let freedBytes: Int64?
}

struct SessionSummaryView: View {
    let result: SessionResult
    let categoryTitle: String
    let onBackToCategory: () -> Void
    let onReturnHome: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Session complete")
                .font(.title2.weight(.semibold))

            VStack(spacing: 12) {
                tallyRow("Kept", value: "\(result.keptCount)", symbol: "heart.fill", tint: .green)
                tallyRow("Deleted", value: "\(result.deletedCount)", symbol: "trash.fill", tint: .red)
                tallyRow("Space freed", value: freedText, symbol: "internaldrive", tint: .blue)
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button("Back to \(categoryTitle)", action: onBackToCategory)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("Return Home", action: onReturnHome)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var freedText: String {
        guard let bytes = result.freedBytes else { return "unavailable" }
        guard bytes > 0 else { return "0 MB" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func tallyRow(_ label: String, value: String, symbol: String, tint: Color) -> some View {
        HStack {
            Label(label, systemImage: symbol).foregroundStyle(tint)
            Spacer()
            Text(value).font(.headline)
        }
    }
}
