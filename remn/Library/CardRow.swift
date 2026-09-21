import SwiftUI

struct CardRow: View {
    let card: Flashcard

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(RemnFormatters.usefulLine(card.frontMarkdown))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(3)
                Text(RemnFormatters.dueStatus(for: card))
                    .font(RemnTypography.smallControl)
                    .foregroundStyle(card.due <= .now && card.state != .new ? Color.remnAccent : Color.remnGraphite)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.remnGraphite)
                .padding(.top, 4)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            ScribbleDivider(seed: card.id.hashValue)
        }
        .contentShape(Rectangle())
    }
}
