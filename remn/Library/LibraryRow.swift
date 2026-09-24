import SwiftUI

/// A subject or deck on the page: its name, and how much of it is waiting.
struct LibraryRow: View {
    let title: String
    let dueCount: Int
    let totalCount: Int
    /// Tighter type for the sidebar of the split layout.
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 5) {
            HandwrittenText(verbatim: title, weight: 0.3)
                .font(compact ? RemnTypography.display(23, relativeTo: .title3) : RemnTypography.rowTitle)
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
            .font(compact ? RemnTypography.caption : RemnTypography.note)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, compact ? 11 : 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Dims a row while it's pressed, the way a page darkens under a finger.
struct InkRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        InkRowBody(configuration: configuration)
    }
}

private struct InkRowBody: View {
    let configuration: ButtonStyleConfiguration
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : (isHovered ? 0.78 : 1))
            .animation(.easeOut(duration: configuration.isPressed ? 0.05 : 0.2), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

/// A row in the sidebar. The chosen one is lifted off the page as a small index card;
/// under the pointer a row gets a faint pencil wash.
struct SidebarRowStyle: ButtonStyle {
    var isSelected: Bool
    var seed: Int

    func makeBody(configuration: Configuration) -> some View {
        SidebarRowBody(configuration: configuration, isSelected: isSelected, seed: seed)
    }
}

private struct SidebarRowBody: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    let seed: Int
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .background {
                ZStack {
                    if isSelected {
                        InkHatch(seed: seed ^ 0x51, spacing: 4)
                            .fill(Color.remnAccent.opacity(0.5))
                            .clipShape(InkPatch(seed: seed ^ 0x52, cornerRadius: 12))
                            .offset(x: 3, y: 4)
                        InkBox(
                            seed: seed,
                            cornerRadius: 12,
                            fill: .remnCardPaper,
                            outline: .remnInk,
                            pen: .fine,
                            registration: CGSize(width: 0.8, height: 1.1)
                        )
                    } else if isHovered || configuration.isPressed {
                        InkPatch(seed: seed ^ 0x53, cornerRadius: 12)
                            .fill(Color.remnInk.opacity(configuration.isPressed ? 0.08 : 0.045))
                    }
                }
                .transition(.opacity)
            }
            .padding(.trailing, isSelected ? 3 : 0)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.25, bounce: 0.3), value: isSelected)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
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
