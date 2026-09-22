import SwiftUI
import SwiftUIMath
import Textual

enum CardRenderingContext {
    case study
    case detail
    case preview
    case export
}

struct CardContentView: View {
    let markdown: String
    var context: CardRenderingContext = .detail
    @ScaledMetric(relativeTo: .body) private var baseMathSize = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(MarkdownRenderSource.blocks(in: markdown).enumerated()), id: \.offset) { _, block in
                switch block {
                case .markdown(let markdown):
                    structuredText(markdown)
                case .displayMath(let latex):
                    displayMath(latex)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func structuredText(_ markdown: String) -> some View {
        StructuredText(
            markdown: markdown,
            patternOptions: .init(mathExpressions: true)
        )
        .textual.structuredTextStyle(.gitHub)
        .textual.mathProperties(.init(fontScale: mathScale, textAlignment: .center))
        .textual.imageAttachmentLoader(OfflineAttachmentLoader())
        .textual.emojiAttachmentLoader(OfflineAttachmentLoader())
        .textual.overflowMode(.scroll)
        .textual.textSelection(.enabled)
        .font(contentFont)
        .foregroundStyle(Color.remnInk)
        .environment(\.openURL, OpenURLAction { _ in .discarded })
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityLabel(Text(markdown))
    }

    private func displayMath(_ latex: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                math(latex)
                Spacer(minLength: 0)
            }
            ScrollView(.horizontal, showsIndicators: true) {
                math(latex)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityLabel(Text(verbatim: latex))
    }

    private func math(_ latex: String) -> some View {
        Math(latex)
            .mathFont(.init(name: .latinModern, size: mathFontSize))
            .mathTypesettingStyle(.display)
            .mathRenderingMode(.monochrome)
            .foregroundStyle(Color.remnInk)
    }

    private var mathFontSize: CGFloat {
        switch context {
        case .study: baseMathSize * 1.18
        case .detail, .preview, .export: baseMathSize
        }
    }

    private var mathScale: CGFloat {
        switch context {
        case .study: 1.26
        case .detail, .preview, .export: 1.2
        }
    }

    private var contentFont: Font {
        switch context {
        case .study: RemnTypography.display(25, relativeTo: .title3)
        case .detail, .preview: RemnTypography.display(22, relativeTo: .body)
        case .export: RemnTypography.display(22, relativeTo: .body)
        }
    }
}
