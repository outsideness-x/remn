import Foundation
import SwiftData

@Model
final class Flashcard: Identifiable {
    @Attribute(.unique) var id: UUID
    var frontMarkdown: String
    var backMarkdown: String
    var createdAt: Date
    var updatedAt: Date
    var deck: Deck?

    var stateRaw: Int
    var due: Date
    var lastReview: Date?
    var stability: Double
    var difficulty: Double
    var elapsedDays: Double
    var scheduledDays: Double
    var learningStep: Int
    var repetitions: Int
    var lapses: Int

    @Relationship(deleteRule: .cascade, inverse: \ReviewLogEntry.card)
    var reviewLogs: [ReviewLogEntry] = []

    init(
        id: UUID = UUID(),
        deck: Deck,
        frontMarkdown: String,
        backMarkdown: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.deck = deck
        self.frontMarkdown = frontMarkdown
        self.backMarkdown = backMarkdown
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.stateRaw = ScheduleState.new.rawValue
        self.due = createdAt
        self.stability = 0
        self.difficulty = 0
        self.elapsedDays = 0
        self.scheduledDays = 0
        self.learningStep = 0
        self.repetitions = 0
        self.lapses = 0
    }

    var state: ScheduleState {
        get { ScheduleState(rawValue: stateRaw) ?? .new }
        set { stateRaw = newValue.rawValue }
    }

    var scheduleSnapshot: ScheduleSnapshot {
        get {
            ScheduleSnapshot(
                stateRaw: stateRaw,
                due: due,
                lastReview: lastReview,
                stability: stability,
                difficulty: difficulty,
                elapsedDays: elapsedDays,
                scheduledDays: scheduledDays,
                learningStep: learningStep,
                repetitions: repetitions,
                lapses: lapses
            )
        }
        set {
            stateRaw = newValue.stateRaw
            due = newValue.due
            lastReview = newValue.lastReview
            stability = newValue.stability
            difficulty = newValue.difficulty
            elapsedDays = newValue.elapsedDays
            scheduledDays = newValue.scheduledDays
            learningStep = newValue.learningStep
            repetitions = newValue.repetitions
            lapses = newValue.lapses
        }
    }
}
