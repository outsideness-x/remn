import SwiftUI

struct ScribbleDivider: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let middle = size.height / 2
            let start = middle + offset(0)
            let end = middle + offset(3)
            path.move(to: CGPoint(x: 0, y: start))
            path.addCurve(
                to: CGPoint(x: size.width, y: end),
                control1: CGPoint(x: size.width * 0.34, y: middle + offset(1)),
                control2: CGPoint(x: size.width * 0.67, y: middle + offset(2))
            )
            context.stroke(
                path,
                with: .color(.remnInk.opacity(0.48)),
                style: StrokeStyle(lineWidth: 1.15, lineCap: .round)
            )
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }

    private func offset(_ index: Int) -> CGFloat {
        let value = abs((seed &* 37 &+ index &* 19) % 7) - 3
        return CGFloat(value) * 0.18
    }
}
