import Foundation
import SwiftData

@Model
final class ReviewLogEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var card: Flashcard?
    var timestamp: Date
    var ratingRaw: Int
    var elapsedInterval: Double
    var scheduledInterval: Double

    var previousStateRaw: Int
    var previousDue: Date
    var previousLastReview: Date?
    var previousStability: Double
    var previousDifficulty: Double
    var previousElapsedDays: Double
    var previousScheduledDays: Double
    var previousLearningStep: Int
    var previousRepetitions: Int
    var previousLapses: Int

    var resultingStateRaw: Int
    var resultingDue: Date
    var resultingLastReview: Date?
    var resultingStability: Double
    var resultingDifficulty: Double
    var resultingElapsedDays: Double
    var resultingScheduledDays: Double
    var resultingLearningStep: Int
    var resultingRepetitions: Int
    var resultingLapses: Int

    init(
        id: UUID = UUID(),
        card: Flashcard,
        timestamp: Date,
        rating: StudyRating,
        previous: ScheduleSnapshot,
        resulting: ScheduleSnapshot,
        elapsedInterval: Double,
        scheduledInterval: Double
    ) {
        self.id = id
        self.card = card
        self.timestamp = timestamp
        self.ratingRaw = rating.rawValue
        self.elapsedInterval = elapsedInterval
        self.scheduledInterval = scheduledInterval
        self.previousStateRaw = previous.stateRaw
        self.previousDue = previous.due
        self.previousLastReview = previous.lastReview
        self.previousStability = previous.stability
        self.previousDifficulty = previous.difficulty
        self.previousElapsedDays = previous.elapsedDays
        self.previousScheduledDays = previous.scheduledDays
        self.previousLearningStep = previous.learningStep
        self.previousRepetitions = previous.repetitions
        self.previousLapses = previous.lapses
        self.resultingStateRaw = resulting.stateRaw
        self.resultingDue = resulting.due
        self.resultingLastReview = resulting.lastReview
        self.resultingStability = resulting.stability
        self.resultingDifficulty = resulting.difficulty
        self.resultingElapsedDays = resulting.elapsedDays
        self.resultingScheduledDays = resulting.scheduledDays
        self.resultingLearningStep = resulting.learningStep
        self.resultingRepetitions = resulting.repetitions
        self.resultingLapses = resulting.lapses
    }

    var rating: StudyRating? { StudyRating(rawValue: ratingRaw) }

    var previousSnapshot: ScheduleSnapshot {
        ScheduleSnapshot(
            stateRaw: previousStateRaw,
            due: previousDue,
            lastReview: previousLastReview,
            stability: previousStability,
            difficulty: previousDifficulty,
            elapsedDays: previousElapsedDays,
            scheduledDays: previousScheduledDays,
            learningStep: previousLearningStep,
            repetitions: previousRepetitions,
            lapses: previousLapses
        )
    }
}
