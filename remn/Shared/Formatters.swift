import Foundation

enum RemnFormatters {
    /// A compact, localized distance in time: "10m", "3d" — "10 мин", "3 дн".
    static func interval(from now: Date, to date: Date) -> String {
        let seconds = max(0, date.timeIntervalSince(now))
        if seconds < 3_600 {
            return String(localized: "interval.minutes \(max(1, Int((seconds / 60).rounded())))")
        }
        if seconds < 86_400 {
            return String(localized: "interval.hours \(max(1, Int((seconds / 3_600).rounded())))")
        }
        if seconds < 86_400 * 30 {
            return String(localized: "interval.days \(max(1, Int((seconds / 86_400).rounded())))")
        }
        if seconds < 86_400 * 365 {
            return String(localized: "interval.months \(max(1, Int((seconds / (86_400 * 30)).rounded())))")
        }
        return String(localized: "interval.years \(max(1, Int((seconds / (86_400 * 365)).rounded())))")
    }

    static func dueStatus(for card: Flashcard, now: Date = .now) -> String {
        if card.state == .new { return String(localized: "status.new") }
        if card.due <= now { return String(localized: "status.due") }
        return card.due.formatted(.dateTime.month(.abbreviated).day()).lowercased()
    }

    static func usefulLine(_ markdown: String) -> String {
        markdown
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .replacingOccurrences(of: #"[#*`_$>]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? String(localized: "card.untitled")
    }
}
