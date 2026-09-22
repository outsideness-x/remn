import SwiftUI

struct ScreenTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HandwrittenText(title)
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
    case flip
    case down
    case info
    case minus
    case upload
    case download
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

            case .flip:
                var curve = Path()
                curve.move(to: CGPoint(x: 5.2, y: 14.3))
                curve.addCurve(
                    to: CGPoint(x: 18.1, y: 10.2),
                    control1: CGPoint(x: 5.5, y: 7.3),
                    control2: CGPoint(x: 13.4, y: 5.5)
                )
                curve.move(to: CGPoint(x: 13.2, y: 7.2))
                curve.addLine(to: CGPoint(x: 18.4, y: 10.1))
                curve.addLine(to: CGPoint(x: 15.3, y: 15.1))
                context.stroke(curve, with: .color(color), style: stroke)

            case .down:
                var chevron = Path()
                chevron.move(to: CGPoint(x: 4.5, y: 8.5))
                chevron.addLine(to: CGPoint(x: 12.2, y: 16.3))
                chevron.addLine(to: CGPoint(x: 19.6, y: 8.1))
                context.stroke(chevron, with: .color(color), style: stroke)

            case .info:
                var ring = Path()
                ring.addEllipse(in: CGRect(x: 3.1, y: 3.2, width: 17.8, height: 17.3))
                ring.move(to: CGPoint(x: 12.1, y: 10.5))
                ring.addLine(to: CGPoint(x: 11.8, y: 16.4))
                context.stroke(ring, with: .color(color), style: stroke)
                var dot = Path()
                dot.addEllipse(in: CGRect(x: 10.9, y: 6.7, width: 2.2, height: 2.2))
                context.fill(dot, with: .color(color))

            case .minus:
                var minus = Path()
                minus.move(to: CGPoint(x: 4, y: 12.3))
                minus.addLine(to: CGPoint(x: 20, y: 11.8))
                context.stroke(minus, with: .color(color), style: stroke)

            case .upload, .download:
                let pointsUp = kind == .upload
                var transfer = Path()
                transfer.move(to: CGPoint(x: 4, y: 19.5))
                transfer.addLine(to: CGPoint(x: 20, y: 19.1))
                transfer.move(to: CGPoint(x: 12.1, y: pointsUp ? 18 : 5))
                transfer.addLine(to: CGPoint(x: 11.8, y: pointsUp ? 5 : 18))
                let arrowY: CGFloat = pointsUp ? 5 : 18
                let wingY: CGFloat = pointsUp ? 10.5 : 12.5
                transfer.move(to: CGPoint(x: 6.8, y: wingY))
                transfer.addLine(to: CGPoint(x: 11.8, y: arrowY))
                transfer.addLine(to: CGPoint(x: 17.1, y: wingY))
                context.stroke(transfer, with: .color(color), style: stroke)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct HandmadeSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        GeometryReader { proxy in
            let thumbSize: CGFloat = 24
            let travel = max(1, proxy.size.width - thumbSize)
            let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbX = travel * CGFloat(progress)

            ZStack(alignment: .leading) {
                Canvas { context, size in
                    let y = size.height / 2
                    var track = Path()
                    track.move(to: CGPoint(x: thumbSize / 2, y: y + 0.6))
                    track.addCurve(
                        to: CGPoint(x: size.width - thumbSize / 2, y: y - 0.4),
                        control1: CGPoint(x: size.width * 0.34, y: y - 1.0),
                        control2: CGPoint(x: size.width * 0.68, y: y + 0.8)
                    )
                    context.stroke(
                        track,
                        with: .color(.remnInk.opacity(0.50)),
                        style: StrokeStyle(lineWidth: 1.25, lineCap: .round)
                    )

                    var active = Path()
                    active.move(to: CGPoint(x: thumbSize / 2, y: y + 0.6))
                    active.addLine(to: CGPoint(x: thumbX + thumbSize / 2, y: y))
                    context.stroke(
                        active,
                        with: .color(.remnAccent),
                        style: StrokeStyle(lineWidth: 2.1, lineCap: .round)
                    )
                }

                DoodleSliderThumb()
                    .offset(x: thumbX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(at: gesture.location.x - thumbSize / 2, travel: travel)
                    }
            )
        }
        .frame(height: 34)
        .accessibilityRepresentation {
            Slider(value: $value, in: range, step: step)
                .accessibilityLabel(Text("settings.retention"))
                .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
        }
    }

    private func updateValue(at x: CGFloat, travel: CGFloat) {
        let fraction = min(max(Double(x / travel), 0), 1)
        let raw = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
        value = min(range.upperBound, max(range.lowerBound, (raw / step).rounded() * step))
    }
}

private struct DoodleSliderThumb: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width * 0.51, y: 1.2))
            path.addCurve(
                to: CGPoint(x: 1.3, y: size.height * 0.52),
                control1: CGPoint(x: 5.7, y: 0.5),
                control2: CGPoint(x: 0.5, y: 5.8)
            )
            path.addCurve(
                to: CGPoint(x: size.width * 0.49, y: size.height - 1.0),
                control1: CGPoint(x: 1.0, y: size.height - 5.4),
                control2: CGPoint(x: 5.8, y: size.height - 0.4)
            )
            path.addCurve(
                to: CGPoint(x: size.width - 1.2, y: size.height * 0.49),
                control1: CGPoint(x: size.width - 5.8, y: size.height - 1.1),
                control2: CGPoint(x: size.width - 0.5, y: size.height - 5.6)
            )
            path.addCurve(
                to: CGPoint(x: size.width * 0.51, y: 1.2),
                control1: CGPoint(x: size.width - 1.0, y: 5.6),
                control2: CGPoint(x: size.width - 5.6, y: 0.8)
            )
            context.fill(path, with: .color(.remnCardPaper))
            context.stroke(path, with: .color(.remnAccent), style: StrokeStyle(lineWidth: 1.7))
        }
        .frame(width: 24, height: 24)
    }
}

struct DoodleSelectionMark: View {
    let selected: Bool

    var body: some View {
        Canvas { context, size in
            let color = selected ? Color.remnAccent : Color.remnGraphite
            let stroke = StrokeStyle(lineWidth: selected ? 1.8 : 1.3, lineCap: .round, lineJoin: .round)
            var ring = Path()
            ring.move(to: CGPoint(x: size.width * 0.50, y: 1.5))
            ring.addCurve(
                to: CGPoint(x: 1.5, y: size.height * 0.51),
                control1: CGPoint(x: size.width * 0.20, y: 0.8),
                control2: CGPoint(x: 0.7, y: size.height * 0.22)
            )
            ring.addCurve(
                to: CGPoint(x: size.width * 0.51, y: size.height - 1.3),
                control1: CGPoint(x: 1.2, y: size.height * 0.80),
                control2: CGPoint(x: size.width * 0.22, y: size.height - 0.8)
            )
            ring.addCurve(
                to: CGPoint(x: size.width - 1.4, y: size.height * 0.49),
                control1: CGPoint(x: size.width * 0.80, y: size.height - 1.4),
                control2: CGPoint(x: size.width - 0.8, y: size.height * 0.78)
            )
            ring.addCurve(
                to: CGPoint(x: size.width * 0.50, y: 1.5),
                control1: CGPoint(x: size.width - 1.1, y: size.height * 0.20),
                control2: CGPoint(x: size.width * 0.79, y: 1.0)
            )
            context.stroke(ring, with: .color(color), style: stroke)

            if selected {
                var check = Path()
                check.move(to: CGPoint(x: size.width * 0.24, y: size.height * 0.52))
                check.addLine(to: CGPoint(x: size.width * 0.43, y: size.height * 0.70))
                check.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.28))
                context.stroke(check, with: .color(color), style: stroke)
            }
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }
}
