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
        case .bold: "B"
        case .inlineCode: "<>"
        case .codeBlock: "```"
        case .inlineMath: "$x$"
        case .displayMath: "$$"
        case .bullets: "•"
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(MarkdownInsertion.allCases) { item in
                    Button { insert(item) } label: {
                        Text(item.label)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.remnGraphite)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: item.localizedLabel))
                }
            }
        }
    }
}
