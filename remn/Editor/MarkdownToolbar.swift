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
        VStack(alignment: .leading, spacing: 4) {
            Text("editor.insert")
                .font(RemnTypography.smallControl)
                .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                .foregroundStyle(Color.remnGraphite)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(MarkdownInsertion.allCases.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Text("/")
                                .font(.caption.monospaced())
                                .foregroundStyle(Color.remnGraphite.opacity(0.36))
                                .accessibilityHidden(true)
                        }
                        Button { insert(item) } label: {
                            Text(item.label)
                                .font(.system(.caption, design: .monospaced, weight: .medium))
                                .foregroundStyle(Color.remnInk)
                                .padding(.horizontal, 10)
                                .frame(minHeight: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(verbatim: item.localizedLabel))
                    }
                }
            }
        }
    }
}
