import SwiftData
import SwiftUI

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Bindable var subject: SubjectModel

    @State private var showCreate = false
    @State private var manageDeck: Deck?
    @State private var renameDeck: Deck?
    @State private var deleteDeck: Deck?

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(title: "remn") {
                Button { showCreate = true } label: {
                    DoodleIcon(kind: .plus, color: .remnInk, size: 21)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("deck.new"))
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    ScreenTitle(title: LocalizedStringKey(subject.name))
                    if subject.decks.isEmpty {
                        QuietEmptyState(
                            title: "deck.empty",
                            actionTitle: "deck.make",
                            action: { showCreate = true }
                        )
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(subject.orderedDecks, id: \.id) { deck in
                                HStack(spacing: 2) {
                                    NavigationLink {
                                        DeckDetailView(deck: deck)
                                    } label: {
                                        LibraryRow(
                                            title: deck.name,
                                            dueCount: dueCount(deck.cards),
                                            totalCount: deck.cards.count,
                                            seed: deck.id.hashValue
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    Button { manageDeck = deck } label: {
                                        DoodleIcon(kind: .more, color: .remnGraphite, size: 20)
                                            .frame(width: 44, height: 54)
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
                appState.prepareStudy(subjectIDs: [subject.id])
            } label: {
                HandwrittenText("study.subject")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(WobblyButtonStyle(filled: true, seed: subject.id.hashValue))
            .disabled(subject.cards.isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.remnPaper.opacity(0.97))
        }
        .sheet(isPresented: $showCreate) {
            NameEditorSheet(title: "deck.new") { name in
                let order = (subject.decks.map(\.manualSortOrder).max() ?? -1) + 1
                context.insert(Deck(subject: subject, name: name, manualSortOrder: order))
                subject.updatedAt = .now
                save()
            }
        }
        .sheet(item: $renameDeck) { deck in
            NameEditorSheet(title: "deck.rename", initialValue: deck.name) { name in
                deck.name = name
                deck.updatedAt = .now
                save()
            }
        }
        .handmadeDialog(
            isPresented: Binding(
                get: { manageDeck != nil },
                set: { if !$0 { manageDeck = nil } }
            ),
            title: "deck",
            message: Text(verbatim: manageDeck?.name ?? ""),
            actions: deckActions
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { deleteDeck != nil },
                set: { if !$0 { deleteDeck = nil } }
            ),
            title: "deck.delete.title",
            message: Text("deck.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    if let deleteDeck { context.delete(deleteDeck); save() }
                    deleteDeck = nil
                },
                HandmadeDialogAction("cancel", role: .cancel) { deleteDeck = nil }
            ]
        )
    }

    private var deckActions: [HandmadeDialogAction] {
        guard let deck = manageDeck else { return [] }
        return [
            HandmadeDialogAction("rename", role: .plain) {
                manageDeck = nil
                renameDeck = deck
            },
            HandmadeDialogAction("move.up", role: .plain) { move(deck, by: -1) },
            HandmadeDialogAction("move.down", role: .plain) { move(deck, by: 1) },
            HandmadeDialogAction("delete", role: .destructive) {
                manageDeck = nil
                deleteDeck = deck
            },
            HandmadeDialogAction("cancel", role: .cancel) { manageDeck = nil }
        ]
    }

    private func move(_ deck: Deck, by offset: Int) {
        let decks = subject.orderedDecks
        guard let index = decks.firstIndex(where: { $0.id == deck.id }) else { return }
        let destination = index + offset
        guard decks.indices.contains(destination) else { return }
        let other = decks[destination]
        let oldOrder = deck.manualSortOrder
        deck.manualSortOrder = other.manualSortOrder
        other.manualSortOrder = oldOrder
        save()
    }

    private func dueCount(_ cards: [Flashcard]) -> Int {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        return cards.count { $0.state != .new && $0.due < tomorrow }
    }

    private func save() {
        do { try context.save() } catch { appState.errorMessage = error.localizedDescription }
    }
}
