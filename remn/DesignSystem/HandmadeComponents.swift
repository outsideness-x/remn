import SwiftUI

struct ScreenTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(RemnTypography.pageTitle)
                .remnHandwrittenBounds()
                .foregroundStyle(Color.remnInk)
            ScribbleDivider(seed: 31)
                .frame(width: 58)
        }
    }
}

struct WobblyButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let filled: Bool
    let seed: Int

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RemnTypography.control)
            .remnHandwrittenBounds()
            .foregroundStyle(filled ? Color.remnPaper : Color.remnInk)
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .background {
                WobblyRoundedRectangle(seed: seed, cornerRadius: 18)
                    .fill(filled ? Color.remnAccent : Color.remnSurface)
            }
            .overlay {
                WobblyRoundedRectangle(seed: seed, cornerRadius: 18)
                    .stroke(Color.remnInk, lineWidth: filled ? 0 : 1.5)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .offset(y: configuration.isPressed && !reduceMotion ? 1.5 : 0)
    }
}

struct StackedCardsDoodle: View {
    var ink: Color = .remnInk
    var accent: Color = .remnAccent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(ink, lineWidth: 2)
                .frame(width: 43, height: 27)
                .rotationEffect(.degrees(-7))
                .offset(x: -3, y: -5)
            RoundedRectangle(cornerRadius: 3)
                .stroke(accent, lineWidth: 2.5)
                .frame(width: 43, height: 27)
                .rotationEffect(.degrees(4))
                .offset(x: 4, y: 5)
        }
        .frame(width: 58, height: 50)
        .accessibilityHidden(true)
    }
}

enum DoodleIconKind {
    case search
    case settings
    case plus
    case back
    case forward
    case more
}

struct DoodleIcon: View {
    let kind: DoodleIconKind
    var color: Color = .remnInk
    var size: CGFloat = 22

    var body: some View {
        Canvas { context, canvas in
            let scale = min(canvas.width, canvas.height) / 24
            context.scaleBy(x: scale, y: scale)
            let stroke = StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round)

            switch kind {
            case .search:
                var lens = Path()
                lens.move(to: CGPoint(x: 10.8, y: 3.8))
                lens.addCurve(
                    to: CGPoint(x: 4.2, y: 10.4),
                    control1: CGPoint(x: 6.9, y: 3.1),
                    control2: CGPoint(x: 3.7, y: 6.3)
                )
                lens.addCurve(
                    to: CGPoint(x: 10.9, y: 17.2),
                    control1: CGPoint(x: 4.4, y: 14.4),
                    control2: CGPoint(x: 7.2, y: 17.6)
                )
                lens.addCurve(
                    to: CGPoint(x: 17.1, y: 10.2),
                    control1: CGPoint(x: 14.8, y: 16.9),
                    control2: CGPoint(x: 17.7, y: 14.1)
                )
                lens.addCurve(
                    to: CGPoint(x: 10.8, y: 3.8),
                    control1: CGPoint(x: 16.8, y: 6.3),
                    control2: CGPoint(x: 14.2, y: 3.4)
                )
                lens.move(to: CGPoint(x: 15.2, y: 15.2))
                lens.addLine(to: CGPoint(x: 21, y: 21))
                context.stroke(lens, with: .color(color), style: stroke)

            case .settings:
                var hub = Path()
                hub.addEllipse(in: CGRect(x: 8, y: 8.2, width: 8, height: 7.6))
                context.stroke(hub, with: .color(color), style: stroke)
                for index in 0..<8 {
                    let angle = Double(index) * .pi / 4 + 0.04
                    let inner = CGFloat(5.7 + Double(index % 2) * 0.35)
                    let outer = CGFloat(9.1 + Double(index % 3) * 0.22)
                    let cosine = CGFloat(cos(angle))
                    let sine = CGFloat(sin(angle))
                    var ray = Path()
                    ray.move(to: CGPoint(x: 12 + cosine * inner, y: 12 + sine * inner))
                    ray.addLine(to: CGPoint(x: 12 + cosine * outer, y: 12 + sine * outer))
                    context.stroke(ray, with: .color(color), style: stroke)
                }

            case .plus:
                var plus = Path()
                plus.move(to: CGPoint(x: 4, y: 12.4))
                plus.addLine(to: CGPoint(x: 20, y: 11.8))
                plus.move(to: CGPoint(x: 12.2, y: 4))
                plus.addLine(to: CGPoint(x: 11.7, y: 20))
                context.stroke(plus, with: .color(color), style: stroke)

            case .back:
                var arrow = Path()
                arrow.move(to: CGPoint(x: 15.8, y: 3.8))
                arrow.addLine(to: CGPoint(x: 7.6, y: 12.2))
                arrow.addLine(to: CGPoint(x: 15.5, y: 20.1))
                context.stroke(arrow, with: .color(color), style: stroke)

            case .forward:
                var arrow = Path()
                arrow.move(to: CGPoint(x: 3.5, y: 12.3))
                arrow.addLine(to: CGPoint(x: 19.7, y: 11.8))
                arrow.move(to: CGPoint(x: 13.2, y: 5.4))
                arrow.addLine(to: CGPoint(x: 20, y: 11.8))
                arrow.addLine(to: CGPoint(x: 13.7, y: 18.5))
                context.stroke(arrow, with: .color(color), style: stroke)

            case .more:
                for index in 0..<3 {
                    let x = CGFloat(5 + index * 7)
                    var dot = Path()
                    dot.addEllipse(in: CGRect(x: x - 1.15, y: 10.85, width: 2.3, height: 2.3))
                    context.fill(dot, with: .color(color))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
