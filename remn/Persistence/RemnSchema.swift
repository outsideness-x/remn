import SwiftData

/// Ready for iCloud: no unique constraints, a default for every value, optional relationships,
/// and a link from a card back to the note it came from.
enum RemnSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            SubjectModel.self,
            Deck.self,
            Flashcard.self,
            ReviewLogEntry.self,
            StudySessionRecord.self
        ]
    }
}

enum RemnMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [RemnSchemaV1.self, RemnSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: RemnSchemaV1.self, toVersion: RemnSchemaV2.self)]
    }
}
