import Foundation
import SwiftData

@Model
final class SubjectModel: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var manualSortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \Deck.subject)
    var decks: [Deck]? = []

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        manualSortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.manualSortOrder = manualSortOrder
    }

    var allDecks: [Deck] { decks ?? [] }

    var orderedDecks: [Deck] {
        allDecks.sorted {
            if $0.manualSortOrder == $1.manualSortOrder { return $0.createdAt < $1.createdAt }
            return $0.manualSortOrder < $1.manualSortOrder
        }
    }

    var cards: [Flashcard] { allDecks.flatMap(\.allCards) }
}
