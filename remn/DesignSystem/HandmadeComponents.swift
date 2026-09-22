import SwiftUI

struct ScreenTitle: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HandwrittenText(verbatim: title)
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
        Canvas { context, _ in
            var back = Path()
            back.move(to: CGPoint(x: 6, y: 9))
            back.addQuadCurve(to: CGPoint(x: 47, y: 6), control: CGPoint(x: 27, y: 5))
            back.addQuadCurve(to: CGPoint(x: 49, y: 32), control: CGPoint(x: 48, y: 19))
            back.addQuadCurve(to: CGPoint(x: 8, y: 35), control: CGPoint(x: 27, y: 34))
            back.addQuadCurve(to: CGPoint(x: 6, y: 9), control: CGPoint(x: 5, y: 23))
            context.stroke(back, with: .color(ink), style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))

            var front = Path()
            front.move(to: CGPoint(x: 11, y: 17))
            front.addQuadCurve(to: CGPoint(x: 52, y: 18), control: CGPoint(x: 31, y: 15))
            front.addQuadCurve(to: CGPoint(x: 53, y: 43), control: CGPoint(x: 55, y: 30))
            front.addQuadCurve(to: CGPoint(x: 12, y: 42), control: CGPoint(x: 33, y: 45))
            front.addQuadCurve(to: CGPoint(x: 11, y: 17), control: CGPoint(x: 9, y: 29))
            context.stroke(front, with: .color(accent), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 58, height: 50)
        .accessibilityHidden(true)
    }
}
