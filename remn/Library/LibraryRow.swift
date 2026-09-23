import SwiftUI

/// A subject or deck on the page: its name, and how much of it is waiting.
struct LibraryRow: View {
    let title: String
    let dueCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HandwrittenText(verbatim: title, weight: 0.3)
                .font(RemnTypography.rowTitle)
                .foregroundStyle(Color.remnInk)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            HStack(spacing: 8) {
                if dueCount > 0 {
                    HandwrittenText("count.due \(dueCount)")
                        .foregroundStyle(Color.remnAccent)
                    HandwrittenText(verbatim: "·")
                        .foregroundStyle(Color.remnGraphite)
                        .accessibilityHidden(true)
                }
                HandwrittenText("count.cards \(totalCount)")
                    .foregroundStyle(Color.remnGraphite)
            }
            .font(RemnTypography.note)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Dims a row while it's pressed, the way a page darkens under a finger.
struct InkRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .animation(.easeOut(duration: configuration.isPressed ? 0.05 : 0.2), value: configuration.isPressed)
    }
}

extension Array where Element == Flashcard {
    /// Reviews that fall due before the end of today.
    func dueTodayCount(now: Date = .now) -> Int {
        let calendar = Calendar.current
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return count { $0.state != .new && $0.due < endOfToday }
    }
}
