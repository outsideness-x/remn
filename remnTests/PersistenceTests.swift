import SwiftData
import XCTest
@testable import remn

@MainActor
final class PersistenceTests: XCTestCase {
    func testRelationshipsEditsAndCascadeDelete() throws {
        let container = try TestStore.makeContainer()
        let context = ModelContext(container)
        let (subject, deck, card) = TestStore.makeCard()
        context.insert(subject)
        context.insert(deck)
        context.insert(card)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SubjectModel>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Deck>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Flashcard>()), 1)
        card.frontMarkdown = "edited"
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<Flashcard>()).first?.frontMarkdown, "edited")

        let schedule = card.scheduleSnapshot
        card.backMarkdown = "edited answer"
        try context.save()
        XCTAssertEqual(card.scheduleSnapshot, schedule)

        let relaunchedContext = ModelContext(container)
        let relaunchedCard = try XCTUnwrap(relaunchedContext.fetch(FetchDescriptor<Flashcard>()).first)
        XCTAssertEqual(relaunchedCard.frontMarkdown, "edited")
        XCTAssertEqual(relaunchedCard.deck?.subject?.name, "Mathematics")

        context.delete(subject)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Deck>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Flashcard>()), 0)
    }
}
