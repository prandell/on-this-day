import SwiftUI

struct SpinningSausageView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPaused = false
    @State private var rotation = 0.0
    @State private var spinStartedAt: Date?

    private var shouldSpin: Bool {
        !reduceMotion && !isPaused && scenePhase == .active
    }

    var body: some View {
        GeometryReader { geometry in
            let diameter = max(0, min(geometry.size.width - 48, geometry.size.height * 0.55))

            VStack(spacing: 20) {
                Spacer(minLength: 12)

                Text("sausage.")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 1, green: 0.78, blue: 0.48))

                Text("ALL ROLL. NO CULL.")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.6))

                Spacer(minLength: 12)

                Button {
                    isPaused.toggle()
                } label: {
                    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !shouldSpin)) { context in
                        SausageArtwork()
                            .frame(width: diameter, height: diameter * 140 / 320)
                            .rotationEffect(.degrees(angle(at: context.date)))
                            .frame(width: diameter, height: diameter)
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(reduceMotion)
                .accessibilityLabel("Sausage")
                .accessibilityValue(reduceMotion ? "Still, Reduce Motion is on" : (isPaused ? "Paused" : "Spinning"))
                .accessibilityHint(reduceMotion ? "" : (isPaused ? "Double tap to spin" : "Double tap to pause"))

                Spacer(minLength: 12)

                Text(reduceMotion ? "a moment of still sausage." : (isPaused ? "tap the sausage to keep rolling." : "tap the sausage to pause."))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(SausageArtwork.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onChange(of: shouldSpin, initial: true) { _, spinning in
            if spinning {
                spinStartedAt = .now
            } else {
                rotation = angle(at: .now).truncatingRemainder(dividingBy: 360)
                spinStartedAt = nil
            }
        }
    }

    private func angle(at date: Date) -> Double {
        rotation + (spinStartedAt.map { date.timeIntervalSince($0) * 90 } ?? 0)
    }
}
