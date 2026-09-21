import SwiftUI

struct QuietEmptyState: View {
    let title: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            StackedCardsDoodle()
                .scaleEffect(1.25)
            Text(title)
                .font(RemnTypography.display(23, weight: .medium, relativeTo: .title3))
                .remnHandwrittenBounds()
                .foregroundStyle(Color.remnInk)
                .multilineTextAlignment(.center)
            Button(action: action) {
                Text(actionTitle)
            }
            .buttonStyle(WobblyButtonStyle(filled: false, seed: 17))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}
