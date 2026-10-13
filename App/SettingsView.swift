import SwiftUI

struct SettingsView: View {
    @Binding var monthsNewestFirst: Bool
    @Binding var showKept: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section(symbol: "calendar", title: "Sort months by") {
                        optionPill("newest first", selected: monthsNewestFirst) { monthsNewestFirst = true }
                        optionPill("oldest first", selected: !monthsNewestFirst) { monthsNewestFirst = false }
                    }
                    section(symbol: "arrow.counterclockwise", title: "Show photos I already kept") {
                        optionPill("no", selected: !showKept) { showKept = false }
                        optionPill("yes", selected: showKept) { showKept = true }
                    }
                }
                .padding(20)
            }
        }
        .background(Theme.panelBackground)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack {
            Theme.wordmark(size: 26)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.black.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.black.opacity(0.08)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(Theme.headerBackground)
    }

    private func section(symbol: String, title: String, @ViewBuilder options: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.black.opacity(0.55))
                .textCase(.uppercase)
            HStack(spacing: 10) {
                options()
            }
        }
    }

    private func optionPill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(.body, design: .rounded).weight(selected ? .bold : .regular))
                .foregroundStyle(selected ? .black : .black.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.black.opacity(0.05)))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(selected ? .black : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
