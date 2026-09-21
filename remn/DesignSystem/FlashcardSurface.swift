import SwiftUI

enum FlashcardSurfaceStyle {
    case compact
    case regular
    case study
    case export

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: 17
        case .regular: 22
        case .study: 24
        case .export: 28
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .compact: 15
        case .regular: 24
        case .study: 27
        case .export: 28
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact: 8
        case .regular, .study, .export: 10
        }
    }
}

struct FlashcardSurface<Content: View>: View {
    let seed: Int
    let style: FlashcardSurfaceStyle
    private let content: Content

    init(
        seed: Int,
        style: FlashcardSurfaceStyle = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.seed = seed
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background {
                ZStack {
                    WobblyRoundedRectangle(seed: seed &+ 109, cornerRadius: style.cornerRadius)
                        .fill(Color.remnAccent.opacity(0.13))
                        .overlay {
                            WobblyRoundedRectangle(seed: seed &+ 109, cornerRadius: style.cornerRadius)
                                .stroke(Color.remnAccent.opacity(0.78), lineWidth: 1.15)
                        }
                        .offset(x: 3, y: 5)

                    WobblyRoundedRectangle(seed: seed &+ 71, cornerRadius: style.cornerRadius)
                        .fill(Color.remnInk.opacity(0.08))
                        .offset(x: 1, y: 2.5)

                    WobblyRoundedRectangle(seed: seed, cornerRadius: style.cornerRadius)
                        .fill(Color.remnCardPaper)
                }
            }
            .overlay {
                WobblyRoundedRectangle(seed: seed, cornerRadius: style.cornerRadius)
                    .stroke(Color.remnInk.opacity(0.72), lineWidth: 1.3)
            }
            .rotationEffect(.degrees(tilt))
            .padding(.horizontal, style == .compact ? 3 : 1)
            .padding(.bottom, 7)
    }

    private var tilt: Double {
        guard style == .compact else { return 0 }
        let step = Int(UInt(bitPattern: seed) % 5) - 2
        return Double(step) * 0.18
    }
}

struct FlashcardSideLabel: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(RemnTypography.smallControl)
            .foregroundStyle(Color.remnGraphite)
    }
}
