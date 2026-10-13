import SwiftUI

/// The same resolution-independent sausage in the app and its widget.
struct SausageArtwork: View {
    static let background = Color(red: 0.07, green: 0.04, blue: 0.03)

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 320, size.height / 140)
            context.translateBy(x: (size.width - 320 * scale) / 2, y: (size.height - 140 * scale) / 2)
            context.scaleBy(x: scale, y: scale)

            // Twisted casing at each end, tucked under the sausage.
            for x in [22.0, 278.0] {
                let casing = Path { path in
                    path.move(to: CGPoint(x: x, y: 55))
                    path.addLine(to: CGPoint(x: x + 20, y: 67))
                    path.addLine(to: CGPoint(x: x + 20, y: 79))
                    path.addLine(to: CGPoint(x: x, y: 91))
                    path.addQuadCurve(to: CGPoint(x: x, y: 55), control: CGPoint(x: x + 9, y: 73))
                }
                context.fill(casing, with: .color(Color(red: 0.72, green: 0.27, blue: 0.11)))
            }

            let sausage = Path { path in
                path.move(to: CGPoint(x: 55, y: 35))
                path.addCurve(to: CGPoint(x: 265, y: 35), control1: CGPoint(x: 110, y: 60), control2: CGPoint(x: 210, y: 60))
                path.addCurve(to: CGPoint(x: 283, y: 95), control1: CGPoint(x: 307, y: 12), control2: CGPoint(x: 318, y: 72))
                path.addCurve(to: CGPoint(x: 37, y: 95), control1: CGPoint(x: 220, y: 135), control2: CGPoint(x: 100, y: 135))
                path.addCurve(to: CGPoint(x: 55, y: 35), control1: CGPoint(x: 2, y: 72), control2: CGPoint(x: 13, y: 12))
                path.closeSubpath()
            }
            context.fill(sausage, with: .linearGradient(
                Gradient(colors: [Color(red: 1, green: 0.66, blue: 0.32), Color(red: 0.84, green: 0.32, blue: 0.12), Color(red: 0.43, green: 0.12, blue: 0.05)]),
                startPoint: CGPoint(x: 160, y: 30), endPoint: CGPoint(x: 160, y: 125)
            ))
            context.stroke(sausage, with: .color(Color(red: 0.35, green: 0.11, blue: 0.04)), lineWidth: 3)

            var surface = context
            surface.clip(to: sausage)
            for x in stride(from: 80.0, through: 240.0, by: 40) {
                let grillMark = Path { path in
                    path.move(to: CGPoint(x: x, y: 55))
                    path.addQuadCurve(to: CGPoint(x: x - 17, y: 97), control: CGPoint(x: x - 18, y: 72))
                }
                surface.stroke(grillMark, with: .color(.black.opacity(0.27)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            }

            let shine = Path { path in
                path.move(to: CGPoint(x: 46, y: 48))
                path.addQuadCurve(to: CGPoint(x: 65, y: 50), control: CGPoint(x: 49, y: 42))
                path.move(to: CGPoint(x: 89, y: 60))
                path.addQuadCurve(to: CGPoint(x: 255, y: 55), control: CGPoint(x: 175, y: 85))
            }
            surface.stroke(shine, with: .color(.white.opacity(0.3)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}
