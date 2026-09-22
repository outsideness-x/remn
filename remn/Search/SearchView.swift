import SwiftData
import SwiftUI

struct SearchView: View {
    @Query private var cards: [Flashcard]
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(title: "search")
            HStack(spacing: 12) {
                DoodleIcon(kind: .search, color: .remnGraphite, size: 20)
                TextField("search.placeholder", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(RemnTypography.control)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) { ScribbleDivider(seed: 64) }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView {
                LazyVStack(spacing: 10) {
                    if query.isEmpty {
                        HandwrittenText("search.prompt")
                            .font(RemnTypography.control)
                            .remnHandwrittenBounds()
                            .foregroundStyle(Color.remnGraphite)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 26)
                    } else if results.isEmpty {
                        HandwrittenText("search.empty")
                            .font(RemnTypography.display(23, weight: .medium, relativeTo: .title3))
                            .remnHandwrittenBounds()
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
        FlashcardSurface(seed: card.id.hashValue, style: .compact) {
            VStack(alignment: .leading, spacing: 9) {
                HandwrittenText(verbatim: context)
                    .font(RemnTypography.smallControl)
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                    .foregroundStyle(Color.remnGraphite)
                    .lineLimit(1)
                HandwrittenText(verbatim: RemnFormatters.usefulLine(card.frontMarkdown))
                    .font(RemnTypography.display(21, weight: .medium, relativeTo: .body))
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(3)
                HStack {
                    FlashcardSideLabel(title: "card.front")
                    Spacer()
                    HandwrittenText(verbatim: RemnFormatters.dueStatus(for: card))
                        .font(RemnTypography.smallControl)
                        .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                        .foregroundStyle(Color.remnGraphite)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var context: String {
        let subject = card.deck?.subject?.name ?? RemnLanguage.localized("subject.unknown")
        let deck = card.deck?.name ?? RemnLanguage.localized("deck.unknown")
        return "\(subject) / \(deck)"
    }
}
