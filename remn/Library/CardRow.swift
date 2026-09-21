import SwiftUI

struct CardRow: View {
    let card: Flashcard

    var body: some View {
        FlashcardSurface(seed: card.id.hashValue, style: .compact) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline) {
                    FlashcardSideLabel(title: "card.front")
                    Spacer(minLength: 8)
                    HandwrittenText(verbatim: RemnFormatters.dueStatus(for: card))
                        .font(RemnTypography.smallControl)
                        .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                        .foregroundStyle(statusColor)
                }
                Text(RemnFormatters.usefulLine(card.frontMarkdown))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var statusColor: Color {
        card.due <= .now && card.state != .new ? .remnAccent : .remnGraphite
    }
}
