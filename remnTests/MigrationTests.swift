import SwiftData
import XCTest
@testable import remn

@MainActor
final class MigrationTests: XCTestCase {
    func testFirstSchemaLibraryOpensInTheCloudReadySchema() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("remn-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("remn.store")
        let cardID = UUID()

        do {
            let schema = Schema(versionedSchema: RemnSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let subject = RemnSchemaV1.SubjectModel(name: "Mathematics")
            let deck = RemnSchemaV1.Deck(subject: subject, name: "Linear Algebra")
            let card = RemnSchemaV1.Flashcard(id: cardID, deck: deck, frontMarkdown: "front", backMarkdown: "back")
            card.stateRaw = ScheduleState.review.rawValue
            card.stability = 12.5
            context.insert(subject)
            context.insert(deck)
            context.insert(card)
            try context.save()
        }

        let schema = Schema(versionedSchema: RemnSchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: RemnMigrationPlan.self,
            configurations: [configuration]
        )
        let context = ModelContext(container)
        let card = try XCTUnwrap(context.fetch(FetchDescriptor<Flashcard>()).first)
        XCTAssertEqual(card.id, cardID)
        XCTAssertEqual(card.frontMarkdown, "front")
        XCTAssertEqual(card.state, .review)
        XCTAssertEqual(card.stability, 12.5)
        XCTAssertEqual(card.deck?.subject?.name, "Mathematics")
        XCTAssertNil(card.sourceNotePath)
        XCTAssertEqual(card.deck?.subject?.allDecks.count, 1)
    }
}
