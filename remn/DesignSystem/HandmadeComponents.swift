import SwiftUI

/// A page title written on, with a red swash under it.
struct ScreenTitle: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HandwrittenText(verbatim: title, weight: 0.7)
                .font(RemnTypography.pageTitle)
                .foregroundStyle(Color.remnInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            TitleSwash(seed: title.inkSeed)
                .inkWritesOn(duration: 0.3, delay: writingTime * 0.8)
        }
        .inkWritesOn(duration: writingTime)
    }

    private var writingTime: Double {
        min(max(Double(title.count) * 0.045, 0.3), 0.8)
    }
}

/// Two index cards, one on top of the other: remn's mark.
struct StackedCardsDoodle: View {
    var ink: Color = .remnInk
    var accent: Color = .remnAccent
    var paper: Color = .remnCardPaper
    var width: CGFloat = 58

    var body: some View {
        let height = width * 0.78
        let pen = InkPen.pen.scaled(by: max(width / 58, 0.6))
        ZStack {
            card(seed: 5_801, pen: pen, color: ink)
                .frame(width: width * 0.7, height: height * 0.6)
                .rotationEffect(.degrees(-8))
                .offset(x: -width * 0.1, y: -height * 0.14)
            card(seed: 5_802, pen: pen, color: accent)
                .frame(width: width * 0.7, height: height * 0.6)
                .rotationEffect(.degrees(5))
                .offset(x: width * 0.1, y: height * 0.12)
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    private func card(seed: Int, pen: InkPen, color: Color) -> some View {
        ZStack {
            InkPatch(seed: seed, cornerRadius: width * 0.07)
                .fill(paper)
            InkRoundedRect(seed: seed, cornerRadius: width * 0.07, pen: pen)
                .ink(color)
        }
    }
}

/// An empty page with one thing to do on it.
struct QuietEmptyState: View {
    let title: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            StackedCardsDoodle(width: 92)
            HandwrittenText(title)
                .font(RemnTypography.sectionTitle)
                .foregroundStyle(Color.remnInk)
                .multilineTextAlignment(.center)
            Button(action: action) {
                HandwrittenText(actionTitle)
            }
            .buttonStyle(InkButtonStyle(kind: .secondary, seed: 17))
        }
        .inkWritesOn(duration: 0.8)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

extension View {
    /// Keeps lines of hand-drawn content a comfortable length on wide screens.
    func remnReadableWidth(_ width: CGFloat = 640) -> some View {
        frame(maxWidth: width)
            .frame(maxWidth: .infinity)
    }
}
