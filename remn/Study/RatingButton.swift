import SwiftUI

struct RatingButton: View {
    let rating: StudyRating
    let interval: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(LocalizedStringKey(rating.titleKey))
                    .font(RemnTypography.smallControl)
                    .remnHandwrittenBounds(horizontal: 3, vertical: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(interval)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.remnGraphite)
            }
            .foregroundStyle(Color.remnInk)
            .frame(maxWidth: .infinity, minHeight: 53)
            .background {
                WobblyRoundedRectangle(seed: rating.rawValue * 23, cornerRadius: 13)
                    .fill(rating == .again ? Color.remnAccent.opacity(0.13) : Color.remnSurface)
            }
            .overlay {
                WobblyRoundedRectangle(seed: rating.rawValue * 23, cornerRadius: 13)
                    .stroke(rating == .again ? Color.remnAccent : Color.remnInk.opacity(0.55), lineWidth: 1.2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(rating.titleKey)))
        .accessibilityValue(Text(interval))
    }
}
