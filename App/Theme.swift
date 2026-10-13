import SwiftUI

/// Visual language for the swipewipe-style redesign: near-black swipe/home screens, a warm dark-brown
/// summary screen, candy-gradient category rows, and a lavender/mint delete/keep color pair throughout.
enum Theme {
    static let appName = "RollCull"
    static let background = Color.black
    static let summaryBackground = Color(red: 0.16, green: 0.13, blue: 0.12)
    static let headerBackground = Color(red: 0.94, green: 0.80, blue: 0.70)
    static let panelBackground = Color(red: 0.90, green: 0.74, blue: 0.62)

    static let brandGradient = LinearGradient(
        colors: [Color(red: 0.31, green: 0.24, blue: 0.88), Color(red: 0.70, green: 0.31, blue: 0.88)],
        startPoint: .leading, endPoint: .trailing
    )

    /// The app's wordmark, styled consistently wherever it appears (Home header, loading screen).
    /// Noteworthy is a built-in iOS font with bubbly, rolled-looking letterforms — no font bundling needed.
    static func wordmark(size: CGFloat = 30) -> some View {
        Text(appName)
            .font(.custom("Noteworthy-Bold", size: size))
            .foregroundStyle(brandGradient)
    }

    static let deleteColor = Color(red: 0.62, green: 0.57, blue: 0.98) // lavender
    static let keepColor = Color(red: 0.48, green: 1.0, blue: 0.70)   // mint green

    static let roundedFont = Font.system(.body, design: .rounded)

    /// Gradient category rows, in display order: on this day, recents, random, bookmarked.
    static let categoryGradients: [LinearGradient] = [
        LinearGradient(colors: [Color(red: 0.90, green: 0.69, blue: 0.47), Color(red: 0.60, green: 0.33, blue: 0.69)],
                        startPoint: .leading, endPoint: .trailing),
        LinearGradient(colors: [Color(red: 0.31, green: 0.86, blue: 0.64), Color(red: 0.18, green: 0.32, blue: 0.93)],
                        startPoint: .leading, endPoint: .trailing),
        LinearGradient(colors: [Color(red: 0.49, green: 0.22, blue: 0.93), Color(red: 0.68, green: 0.76, blue: 0.98)],
                        startPoint: .leading, endPoint: .trailing),
        LinearGradient(colors: [Color(red: 0.95, green: 0.70, blue: 0.30), Color(red: 0.98, green: 0.52, blue: 0.36)],
                        startPoint: .leading, endPoint: .trailing),
    ]

    /// Solid colors cycled through for month rows, paired with the text color that reads on them.
    static let monthRowColors: [(background: Color, text: Color)] = [
        (Color(red: 0.95, green: 0.82, blue: 0.42), .black),
        (Color(red: 0.49, green: 0.60, blue: 0.93), .black),
        (Color(red: 0.86, green: 0.27, blue: 0.24), .white),
        (Color(red: 0.42, green: 0.78, blue: 0.49), .black),
    ]
}
