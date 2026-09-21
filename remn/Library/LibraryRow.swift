import SwiftUI

struct LibraryRow: View {
    let title: String
    let dueCount: Int
    let totalCount: Int
    let seed: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(.title3, design: .default, weight: .semibold))
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(2)
                Text("\(dueCount) \(RemnLanguage.localized("library.due"))  ·  \(totalCount) \(RemnLanguage.localized("library.cards"))")
                    .font(RemnTypography.smallControl)
                    .foregroundStyle(Color.remnGraphite)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.remnGraphite.opacity(0.75))
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            ScribbleDivider(seed: seed)
        }
        .contentShape(Rectangle())
    }
}
