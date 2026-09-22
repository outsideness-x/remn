import SwiftUI

enum MarkdownInsertion: String, CaseIterable, Identifiable {
    case bold
    case inlineCode
    case codeBlock
    case inlineMath
    case displayMath
    case bullets

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bold: RemnLanguage.localized("editor.tool.bold")
        case .inlineCode: RemnLanguage.localized("editor.tool.code")
        case .codeBlock: RemnLanguage.localized("editor.tool.block")
        case .inlineMath: RemnLanguage.localized("editor.tool.math")
        case .displayMath: RemnLanguage.localized("editor.tool.equation")
        case .bullets: RemnLanguage.localized("editor.tool.list")
        }
    }

    var localizedLabel: String {
        switch self {
        case .bold: RemnLanguage.localized("editor.insert.bold")
        case .inlineCode: RemnLanguage.localized("editor.insert.inlineCode")
        case .codeBlock: RemnLanguage.localized("editor.insert.codeBlock")
        case .inlineMath: RemnLanguage.localized("editor.insert.inlineMath")
        case .displayMath: RemnLanguage.localized("editor.insert.displayMath")
        case .bullets: RemnLanguage.localized("editor.insert.bullets")
        }
    }

    var template: String {
        switch self {
        case .bold: "**text**"
        case .inlineCode: "`code`"
        case .codeBlock: "```language\ncode\n```"
        case .inlineMath: "$x$"
        case .displayMath: "$$formula$$"
        case .bullets: "- item"
        }
    }
}

struct MarkdownToolbar: View {
    let insert: (MarkdownInsertion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HandwrittenText("editor.insert")
                .font(RemnTypography.smallControl)
                .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                .foregroundStyle(Color.remnGraphite)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Array(MarkdownInsertion.allCases.enumerated()), id: \.element.id) { index, item in
                    Button { insert(item) } label: {
                        HandwrittenText(verbatim: item.label)
                            .font(RemnTypography.smallControl)
                            .remnHandwrittenBounds(horizontal: 3, vertical: 1)
                            .foregroundStyle(Color.remnInk)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background {
                                WobblyRoundedRectangle(seed: 601 + index * 29, cornerRadius: 8)
                                    .fill(Color.remnSurface.opacity(0.5))
                            }
                            .overlay {
                                WobblyRoundedRectangle(seed: 601 + index * 29, cornerRadius: 8)
                                    .stroke(Color.remnGraphite.opacity(0.55), lineWidth: 1)
                            }
                            .rotationEffect(.degrees(Double(index % 3 - 1) * 0.25))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: item.localizedLabel))
                }
            }
        }
    }
}
