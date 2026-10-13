import SwiftUI

struct SessionResult: Identifiable {
    let id = UUID()
    let keptCount: Int
    let deletedCount: Int
    /// `nil` means KTD6's file-size lookup came back empty for real deletions — show "unavailable", not a false "0 MB".
    let freedBytes: Int64?
    let allTimeFreedBytes: Int64
}

struct SessionSummaryView: View {
    let result: SessionResult
    let categoryTitle: String
    let onBackToCategory: () -> Void
    let onReturnHome: () -> Void

    var body: some View {
        ZStack {
            Theme.summaryBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onReturnHome) {
                        Image(systemName: "xmark")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                Text(categoryTitle.lowercased())
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(freedValueText)
                        .font(.system(size: 76, weight: .heavy, design: .rounded))
                    Text("MB")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.top, 20)

                Text("saved")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 16) {
                    statCard(count: result.keptCount, label: "KEEP", symbol: "checkmark", tint: Theme.keepColor)
                    statCard(count: result.deletedCount, label: "DELETED", symbol: "trash.fill", tint: Theme.deleteColor)
                }
                .padding(.top, 48)
                .padding(.horizontal, 24)

                Text("\(formattedMB(result.allTimeFreedBytes)) saved all-time")
                    .font(.system(.subheadline, design: .rounded).italic())
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 28)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onBackToCategory) {
                        Text("Back to \(categoryTitle)")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.14), in: Capsule())
                    }
                    Button(action: onReturnHome) {
                        Text("Return Home")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white, in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var freedValueText: String {
        guard let bytes = result.freedBytes else { return "—" }
        return String(format: "%.1f", Double(bytes) / 1_048_576)
    }

    private func formattedMB(_ bytes: Int64) -> String {
        String(format: "%.1fMB", Double(bytes) / 1_048_576)
    }

    private func statCard(count: Int, label: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 10) {
            Text("\(count)")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
            Label(label, systemImage: symbol)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
