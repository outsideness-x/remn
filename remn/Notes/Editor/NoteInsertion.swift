import Foundation

/// A change the note toolbar makes to the Markdown around the cursor.
enum NoteInsertion: Equatable {
    case heading
    case bold
    case italic
    case strikethrough
    case highlight
    case inlineCode
    case inlineMath
    case link
    case bullets
    case numbers
    case tasks
    case quote
    case codeBlock
    case mathBlock
    case typst(String)
    case rule
    case table

    struct Edit: Equatable {
        var range: NSRange
        var replacement: String
        /// What to select afterwards, in the text after the edit.
        var selection: NSRange
    }

    func edit(in text: NSString, selection: NSRange) -> Edit {
        let selection = NSRange(
            location: min(selection.location, text.length),
            length: min(selection.length, text.length - min(selection.location, text.length))
        )
        switch self {
        case .bold: return wrap("**", "**", placeholder: String(localized: "insert.placeholder.text"), text, selection)
        case .italic: return wrap("*", "*", placeholder: String(localized: "insert.placeholder.text"), text, selection)
        case .strikethrough: return wrap("~~", "~~", placeholder: String(localized: "insert.placeholder.text"), text, selection)
        case .highlight: return wrap("==", "==", placeholder: String(localized: "insert.placeholder.text"), text, selection)
        case .inlineCode: return wrap("`", "`", placeholder: "code", text, selection)
        case .inlineMath: return wrap("$", "$", placeholder: "x^2", text, selection)
        case .link: return link(text, selection)
        case .heading: return cycleHeading(text, selection)
        case .bullets: return toggleLinePrefix("- ", text, selection)
        case .numbers: return toggleLinePrefix("1. ", text, selection)
        case .tasks: return toggleLinePrefix("- [ ] ", text, selection)
        case .quote: return toggleLinePrefix("> ", text, selection)
        case .codeBlock: return block(open: "```\n", close: "\n```", placeholder: "code", text, selection)
        case .mathBlock: return block(open: "$$\n", close: "\n$$", placeholder: "\\int_0^1 x^2\\,dx = \\frac{1}{3}", text, selection)
        case .typst(let template): return block(open: "```typst\n", close: "\n```", placeholder: template, text, selection)
        case .rule: return block(open: "---", close: "", placeholder: "", text, NSRange(location: NSMaxRange(selection), length: 0))
        case .table:
            let header = String(localized: "insert.table.column")
            return block(
                open: "| \(header) 1 | \(header) 2 |\n| --- | --- |\n| ",
                close: " |  |",
                placeholder: "…",
                text,
                NSRange(location: NSMaxRange(selection), length: 0)
            )
        }
    }

    // MARK: - Inline

    private func wrap(_ open: String, _ close: String, placeholder: String, _ text: NSString, _ selection: NSRange) -> Edit {
        let openLength = (open as NSString).length
        let closeLength = (close as NSString).length
        // Already wrapped: take the markers off again.
        if selection.location >= openLength, NSMaxRange(selection) + closeLength <= text.length,
           text.substring(with: NSRange(location: selection.location - openLength, length: openLength)) == open,
           text.substring(with: NSRange(location: NSMaxRange(selection), length: closeLength)) == close,
           selection.length > 0 {
            let outer = NSRange(location: selection.location - openLength, length: selection.length + openLength + closeLength)
            let inner = text.substring(with: selection)
            return Edit(range: outer, replacement: inner, selection: NSRange(location: outer.location, length: selection.length))
        }
        let inner = selection.length > 0 ? text.substring(with: selection) : placeholder
        let replacement = open + inner + close
        return Edit(
            range: selection,
            replacement: replacement,
            selection: NSRange(location: selection.location + openLength, length: (inner as NSString).length)
        )
    }

    private func link(_ text: NSString, _ selection: NSRange) -> Edit {
        let label = selection.length > 0 ? text.substring(with: selection) : String(localized: "insert.placeholder.link")
        let replacement = "[\(label)](https://)"
        let urlStart = selection.location + (label as NSString).length + 3
        return Edit(range: selection, replacement: replacement, selection: NSRange(location: urlStart, length: 8))
    }

    // MARK: - Lines

    private func lines(_ text: NSString, _ selection: NSRange) -> NSRange {
        text.lineRange(for: selection)
    }

    private func cycleHeading(_ text: NSString, _ selection: NSRange) -> Edit {
        let lineRange = text.lineRange(for: NSRange(location: selection.location, length: 0))
        let line = text.substring(with: lineRange)
        let hashes = line.prefix { $0 == "#" }.count
        let body = hashes > 0 ? String(line.dropFirst(hashes)).drop(while: { $0 == " " }) : Substring(line)
        let next = hashes >= 3 ? 0 : hashes + 1
        let prefix = next == 0 ? "" : String(repeating: "#", count: next) + " "
        let replacement = prefix + body
        let delta = (prefix as NSString).length - (line as NSString).length + (String(body) as NSString).length
        let cursor = max(lineRange.location, min(selection.location + delta, lineRange.location + (replacement as NSString).length))
        return Edit(range: lineRange, replacement: replacement, selection: NSRange(location: cursor, length: 0))
    }

    private func toggleLinePrefix(_ prefix: String, _ text: NSString, _ selection: NSRange) -> Edit {
        let range = lines(text, selection)
        let block = text.substring(with: range)
        var parts = block.components(separatedBy: "\n")
        let trailingNewline = block.hasSuffix("\n")
        if trailingNewline { parts.removeLast() }
        let pattern: String
        switch prefix {
        case "1. ": pattern = #"^\d+\. "#
        case "- [ ] ": pattern = #"^- \[[ xX]\] "#
        default: pattern = "^" + NSRegularExpression.escapedPattern(for: prefix)
        }
        let nonEmpty = parts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let allHave = !nonEmpty.isEmpty && nonEmpty.allSatisfy { $0.range(of: pattern, options: .regularExpression) != nil }
        var number = 0
        let changed = parts.map { line -> String in
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty || parts.count == 1 else { return line }
            if allHave {
                return line.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            // Swap another list marker for this one rather than stacking them.
            let bare = line.replacingOccurrences(of: #"^(- \[[ xX]\] |[-*+] |\d+\. |> )"#, with: "", options: .regularExpression)
            number += 1
            return (prefix == "1. " ? "\(number). " : prefix) + bare
        }
        let replacement = changed.joined(separator: "\n") + (trailingNewline ? "\n" : "")
        let length = (replacement as NSString).length - (trailingNewline ? 1 : 0)
        let selectionAfter = parts.count == 1
            ? NSRange(location: range.location + length, length: 0)
            : NSRange(location: range.location, length: length)
        return Edit(range: range, replacement: replacement, selection: selectionAfter)
    }

    // MARK: - Blocks

    private func block(open: String, close: String, placeholder: String, _ text: NSString, _ selection: NSRange) -> Edit {
        let inner = selection.length > 0 ? text.substring(with: selection) : placeholder
        var lead = ""
        if selection.location > 0, text.character(at: selection.location - 1) != 10 {
            lead = "\n\n"
        } else if selection.location > 1, text.character(at: selection.location - 2) != 10 {
            lead = "\n"
        }
        var tail = ""
        let end = NSMaxRange(selection)
        if end < text.length {
            tail = text.character(at: end) == 10 ? "\n" : "\n\n"
        } else {
            tail = "\n"
        }
        let replacement = lead + open + inner + close + tail
        let innerStart = selection.location + (lead as NSString).length + (open as NSString).length
        return Edit(
            range: selection,
            replacement: replacement,
            selection: NSRange(location: innerStart, length: (inner as NSString).length)
        )
    }
}
