import SwiftData
import SwiftUI

struct SearchView: View {
    @Query private var cards: [Flashcard]
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(title: "search")
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.remnGraphite)
                TextField("search.placeholder", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.body)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) { ScribbleDivider(seed: 64) }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if query.isEmpty {
                        Text("search.prompt")
                            .font(RemnTypography.control)
                            .foregroundStyle(Color.remnGraphite)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 26)
                    } else if results.isEmpty {
                        Text("search.empty")
                            .font(RemnTypography.display(23, weight: .medium, relativeTo: .title3))
                            .foregroundStyle(Color.remnGraphite)
                            .padding(.top, 64)
                    } else {
                        ForEach(results, id: \.id) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                SearchResultRow(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    var results: [Flashcard] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return cards.filter { CardSearch.matches($0, query: query) }
        .sorted { $0.updatedAt > $1.updatedAt }
    }
}

private struct SearchResultRow: View {
    let card: Flashcard

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(RemnFormatters.usefulLine(card.frontMarkdown))
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.remnInk)
                .lineLimit(3)
            HStack {
                Text(context)
                    .lineLimit(1)
                Spacer()
                Text(RemnFormatters.dueStatus(for: card))
            }
            .font(.caption)
            .foregroundStyle(Color.remnGraphite)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            ScribbleDivider(seed: card.id.hashValue)
        }
    }

    private var context: String {
        let subject = card.deck?.subject?.name ?? RemnLanguage.localized("subject.unknown")
        let deck = card.deck?.name ?? RemnLanguage.localized("deck.unknown")
        return "\(subject) / \(deck)"
    }
}
