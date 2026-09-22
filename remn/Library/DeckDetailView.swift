import SwiftData
import SwiftUI

struct DeckDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: \Flashcard.createdAt) private var cards: [Flashcard]
    @Bindable var deck: Deck

    @State private var showCreateCard = false
    @State private var manageCard: Flashcard?
    @State private var editingCard: Flashcard?
    @State private var deleteCard: Flashcard?
    @State private var resetCard: Flashcard?

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(title: "remn") {
                Button { showCreateCard = true } label: {
                    DoodleIcon(kind: .plus, color: .remnInk, size: 21)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("card.new"))
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    ScreenTitle(title: deck.name)
                    if deckCards.isEmpty {
                        QuietEmptyState(
                            title: "card.empty",
                            actionTitle: "card.make",
                            action: { showCreateCard = true }
                        )
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(deckCards, id: \.id) { card in
                                HStack(spacing: 2) {
                                    NavigationLink {
                                        CardDetailView(card: card)
                                    } label: {
                                        CardRow(card: card)
                                    }
                                    .buttonStyle(.plain)

                                    Button { manageCard = card } label: {
                                        DoodleIcon(kind: .more, color: .remnGraphite, size: 20)
                                            .frame(width: 42, height: 58)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(Text("actions"))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 90)
            }
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Button {
                if let subjectID = deck.subject?.id {
                    appState.prepareStudy(subjectIDs: [subjectID], deckID: deck.id)
                }
            } label: {
                HandwrittenText("study.deck").frame(maxWidth: .infinity)
            }
            .buttonStyle(WobblyButtonStyle(filled: true, seed: deck.id.hashValue))
            .disabled(deckCards.isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.remnPaper.opacity(0.97))
        }
        .sheet(isPresented: $showCreateCard) {
            CardEditorView(initialDeck: deck)
        }
        .sheet(item: $editingCard) { card in
            CardEditorView(initialDeck: deck, card: card)
        }
        .handmadeDialog(
            isPresented: Binding(
                get: { manageCard != nil },
                set: { if !$0 { manageCard = nil } }
            ),
            title: "card",
            message: Text(verbatim: manageCard.map { RemnFormatters.usefulLine($0.frontMarkdown) } ?? ""),
            actions: cardActions
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { deleteCard != nil },
                set: { if !$0 { deleteCard = nil } }
            ),
            title: "card.delete.title",
            message: Text("card.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    if let deleteCard { context.delete(deleteCard); save() }
                    deleteCard = nil
                },
                HandmadeDialogAction("cancel", role: .cancel) { deleteCard = nil }
            ]
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { resetCard != nil },
                set: { if !$0 { resetCard = nil } }
            ),
            title: "card.reset.title",
            message: Text("card.reset.message"),
            actions: [
                HandmadeDialogAction("card.reset", role: .destructive) {
                    if let resetCard {
                        do { try ReviewService().reset(resetCard, context: context) }
                        catch { appState.errorMessage = error.localizedDescription }
                    }
                    resetCard = nil
                },
                HandmadeDialogAction("cancel", role: .cancel) { resetCard = nil }
            ]
        )
    }

    private var cardActions: [HandmadeDialogAction] {
        guard let card = manageCard else { return [] }
        return [
            HandmadeDialogAction("edit", role: .plain) {
                manageCard = nil
                editingCard = card
            },
            HandmadeDialogAction("card.duplicate", role: .plain) { duplicate(card) },
            HandmadeDialogAction("card.reset", role: .plain) {
                manageCard = nil
                resetCard = card
            },
            HandmadeDialogAction("delete", role: .destructive) {
                manageCard = nil
                deleteCard = card
            },
            HandmadeDialogAction("cancel", role: .cancel) { manageCard = nil }
        ]
    }

    private func duplicate(_ card: Flashcard) {
        context.insert(
            Flashcard(
                deck: deck,
                frontMarkdown: card.frontMarkdown,
                backMarkdown: card.backMarkdown
            )
        )
        save()
    }

    private func save() {
        do { try context.save() } catch { appState.errorMessage = error.localizedDescription }
    }

    private var deckCards: [Flashcard] {
        cards.filter { $0.deck?.id == deck.id }
    }
}
