import Foundation
import SwiftData

@Model
final class Deck: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var manualSortOrder: Int
    var subject: SubjectModel?

    @Relationship(deleteRule: .cascade, inverse: \Flashcard.deck)
    var cards: [Flashcard] = []

    init(
        id: UUID = UUID(),
        subject: SubjectModel,
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        manualSortOrder: Int = 0
    ) {
        self.id = id
        self.subject = subject
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.manualSortOrder = manualSortOrder
    }

    var orderedCards: [Flashcard] {
        cards.sorted { $0.createdAt < $1.createdAt }
    }
}
