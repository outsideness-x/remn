import SwiftData

enum RemnSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
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
    static var schemas: [any VersionedSchema.Type] { [RemnSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

