import SwiftUI

struct CardExportView: View {
    let card: Flashcard

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(context)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.58))
                .textCase(.uppercase)
            CardContentView(markdown: card.frontMarkdown, context: .export)
                .foregroundStyle(Color.black)
            exportDivider
            CardContentView(markdown: card.backMarkdown, context: .export)
                .foregroundStyle(Color.black)
            Text("remn")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 10)
        }
        .padding(40)
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

