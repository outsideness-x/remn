import SwiftUI

struct RemnNavigationHeader<Trailing: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: LocalizedStringKey
    let trailing: Trailing

    init(
        title: LocalizedStringKey,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                DoodleIcon(kind: .back, color: .remnInk, size: 21)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("back"))

            Spacer(minLength: 0)

            Text(title)
                .font(RemnTypography.navigationTitle)
                .lineLimit(1)

            Spacer(minLength: 0)

            trailing
                .frame(width: 44, height: 44)
        }
        .foregroundStyle(Color.remnInk)
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(Color.remnPaper)
    }
}

extension RemnNavigationHeader where Trailing == Color {
    init(title: LocalizedStringKey) {
        self.init(title: title) { Color.clear }
    }
}
