import Foundation

enum RemnFormatters {
    static func interval(from now: Date, to date: Date) -> String {
        let seconds = max(0, date.timeIntervalSince(now))
        if seconds < 90 { return "1m" }
        if seconds < 3_600 { return "\(max(1, Int((seconds / 60).rounded())))m" }
        if seconds < 86_400 { return "\(max(1, Int((seconds / 3_600).rounded())))h" }
        if seconds < 86_400 * 30 { return "\(max(1, Int((seconds / 86_400).rounded())))d" }
        if seconds < 86_400 * 365 { return "\(max(1, Int((seconds / (86_400 * 30)).rounded())))mo" }
        return "\(max(1, Int((seconds / (86_400 * 365)).rounded())))y"
    }

    static func dueStatus(for card: Flashcard, now: Date = .now) -> String {
        if card.state == .new { return RemnLanguage.localized("status.new") }
        if card.due <= now { return RemnLanguage.localized("status.due") }
        return card.due.formatted(.dateTime.month(.abbreviated).day())
    }

    static func usefulLine(_ markdown: String) -> String {
        markdown
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .replacingOccurrences(of: #"[#*`_$>]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? RemnLanguage.localized("card.untitled")
    }
}
