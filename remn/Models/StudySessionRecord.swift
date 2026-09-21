import Foundation
import SwiftData

@Model
final class StudySessionRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    var subjectIDs: [UUID]
    var deckID: UUID?
    var admittedCardIDs: [UUID]
    var queueCardIDs: [UUID]
    var lastReviewLogID: UUID?
    var reviewedCount: Int
    var initialNewCount: Int

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        subjectIDs: [UUID],
        deckID: UUID?,
        admittedCardIDs: [UUID],
        initialNewCount: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isActive = true
        self.subjectIDs = subjectIDs
        self.deckID = deckID
        self.admittedCardIDs = admittedCardIDs
        self.queueCardIDs = admittedCardIDs
        self.reviewedCount = 0
        self.initialNewCount = initialNewCount
    }
}
