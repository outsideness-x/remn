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
