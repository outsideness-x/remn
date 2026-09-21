import XCTest
@testable import remn

@MainActor
final class StudyQueueTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testOverdueBeforeNewAndMostOverdueFirst() {
        let (subject, deck, oldest) = TestStore.makeCard(createdAt: now.addingTimeInterval(-500))
        oldest.state = .review
        oldest.due = now.addingTimeInterval(-300)
        let newerDue = Flashcard(deck: deck, frontMarkdown: "newer due", backMarkdown: "a")
        newerDue.state = .review
        newerDue.due = now.addingTimeInterval(-30)
        let newCard = Flashcard(deck: deck, frontMarkdown: "new", backMarkdown: "a")

        let result = StudyQueueBuilder.select(
            from: [newCard, newerDue, oldest],
            subjectIDs: [subject.id],
            targetCount: 3,
            now: now
        )
        XCTAssertEqual(result.map(\.id), [oldest.id, newerDue.id, newCard.id])
    }

    func testFutureReviewIsNotPulledToPadSession() {
        let (subject, deck, future) = TestStore.makeCard(createdAt: now)
        future.state = .review
        future.due = now.addingTimeInterval(86_400)
        let fresh = Flashcard(deck: deck, frontMarkdown: "new", backMarkdown: "answer")

        let result = StudyQueueBuilder.select(
            from: [future, fresh],
            subjectIDs: [subject.id],
            targetCount: 30,
            now: now
        )
        XCTAssertEqual(result.map(\.id), [fresh.id])
    }

    func testTargetSmallerThanOverdueCountAndSubjectScope() {
        let (wantedSubject, wantedDeck, first) = TestStore.makeCard(createdAt: now)
        first.state = .review
        first.due = now.addingTimeInterval(-200)
        let second = Flashcard(deck: wantedDeck, frontMarkdown: "second", backMarkdown: "a")
        second.state = .review
        second.due = now.addingTimeInterval(-100)
        let (_, _, other) = TestStore.makeCard(subjectName: "iOS", deckName: "Swift")
        other.state = .review
        other.due = now.addingTimeInterval(-1_000)

        let result = StudyQueueBuilder.select(
            from: [other, second, first],
            subjectIDs: [wantedSubject.id],
            targetCount: 1,
            now: now
        )
        XCTAssertEqual(result.map(\.id), [first.id])
    }

    func testAllDueExcludesNewCards() {
        let (subject, deck, due) = TestStore.makeCard(createdAt: now)
        due.state = .review
        due.due = now.addingTimeInterval(-1)
        let fresh = Flashcard(deck: deck, frontMarkdown: "new", backMarkdown: "answer")
        let result = StudyQueueBuilder.select(
            from: [fresh, due],
            subjectIDs: [subject.id],
            targetCount: nil,
            now: now
        )
        XCTAssertEqual(result.map(\.id), [due.id])
    }

    func testEmptyScopeProducesEmptySessionQueue() {
        let result = StudyQueueBuilder.select(
            from: [],
            subjectIDs: [],
            targetCount: 20,
            now: now
        )
        XCTAssertTrue(result.isEmpty)
    }
}
