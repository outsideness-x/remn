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
                    .font(RemnTypography.display(27, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(2)
                Text("\(dueCount) \(RemnLanguage.localized("library.due"))  ·  \(totalCount) \(RemnLanguage.localized("library.cards"))")
                    .font(RemnTypography.smallControl)
                    .foregroundStyle(Color.remnGraphite)
            }
            Spacer(minLength: 8)
            DoodleIcon(
                kind: .forward,
                color: dueCount > 0 ? .remnAccent : .remnGraphite,
                size: 20
            )
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            ScribbleDivider(seed: seed)
        }
        .contentShape(Rectangle())
    }
}
