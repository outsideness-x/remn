import SwiftUI

struct CardExportView: View {
    let card: Flashcard

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(context)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.58))
                .textCase(.uppercase)
            FlashcardSurface(seed: card.id.hashValue, style: .export) {
                VStack(alignment: .leading, spacing: 20) {
                    FlashcardSideLabel(title: "card.front")
                    CardContentView(markdown: card.frontMarkdown, context: .export)
                    exportDivider
                    FlashcardSideLabel(title: "card.back")
                    CardContentView(markdown: card.backMarkdown, context: .export)
                }
            }
            Text("remn")
                .font(RemnTypography.display(19, weight: .semibold, relativeTo: .body))
                .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                .foregroundStyle(Color.black.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(30)
        .frame(width: 540, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(red: 0.957, green: 0.945, blue: 0.914))
        .environment(\.colorScheme, .light)
    }

    private var context: String {
        [card.deck?.subject?.name, card.deck?.name]
            .compactMap { $0 }
            .joined(separator: " / ")
    }

    private var exportDivider: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height / 2))
            for index in 1...22 {
                let x = size.width * CGFloat(index) / 22
                let y = size.height / 2 + CGFloat((index * 13) % 5 - 2) * 0.45
                path.addLine(to: CGPoint(x: x, y: y))
            }
            context.stroke(path, with: .color(.black.opacity(0.55)), lineWidth: 1.5)
        }
        .frame(height: 10)
    }
}
