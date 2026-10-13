import SwiftUI

/// Branded loading state shown while requesting Photos access and computing Home's rows.
struct LoadingView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Theme.wordmark(size: 44)
                ProgressView()
                    .tint(.white)
            }
        }
    }
}
