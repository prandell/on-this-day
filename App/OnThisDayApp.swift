import SwiftUI

@main
struct OnThisDayApp: App {
    @State private var path: [SessionKind] = []

    var body: some Scene {
        WindowGroup {
            HomeView(path: $path)
                .onOpenURL { _ in path = [.onThisDay(.now)] } // the widget opens onthisday://today, straight into a session
        }
    }
}
