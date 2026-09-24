#if DEBUG
import Foundation
import SwiftData

/// A small, believable library in memory, for design reviews and App Store screenshots.
/// Launch with `-demoLibrary`; the real store on the device is never touched.
@MainActor
enum DemoLibrary {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-demoLibrary")
    }

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: RemnSchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: RemnMigrationPlan.self,
            configurations: [configuration]
        )
        seed(ModelContext(container))
        return container
    }

    private enum Plan {
        /// Never studied.
        case new
        /// Studied before and due right now.
        case due
        /// Studied before and coming back later.
        case later
    }

    private struct DemoCard {
        let front: String
        let back: String
        let plan: Plan
    }

    private struct DemoDeck {
        let name: String
        let cards: [DemoCard]
    }

    private struct DemoSubject {
        let name: String
        let decks: [DemoDeck]
    }

    private static func seed(_ context: ModelContext, now: Date = .now) {
        let russian = Locale.preferredLanguages.first?.hasPrefix("ru") == true
        let scheduler = FSRSSchedulerService()
        for (subjectIndex, subjectPlan) in (russian ? russianLibrary : englishLibrary).enumerated() {
            let subject = SubjectModel(name: subjectPlan.name, manualSortOrder: subjectIndex)
            context.insert(subject)
            for (deckIndex, deckPlan) in subjectPlan.decks.enumerated() {
                let deck = Deck(subject: subject, name: deckPlan.name, manualSortOrder: deckIndex)
                context.insert(deck)
                for (cardIndex, cardPlan) in deckPlan.cards.enumerated() {
                    let created = now.addingTimeInterval(-Double(40 - cardIndex) * 86_400)
                    let card = Flashcard(
                        deck: deck,
                        frontMarkdown: cardPlan.front,
                        backMarkdown: cardPlan.back,
                        createdAt: created,
                        updatedAt: created
                    )
                    context.insert(card)
                    if cardPlan.plan != .new {
                        study(card, plan: cardPlan.plan, seed: cardIndex, scheduler: scheduler, context: context, now: now)
                    }
                }
            }
        }
        try? context.save()
    }

    /// Plays a few past reviews through FSRS so history, intervals and due dates are real.
    private static func study(
        _ card: Flashcard,
        plan: Plan,
        seed: Int,
        scheduler: FSRSSchedulerService,
        context: ModelContext,
        now: Date
    ) {
        var time = card.createdAt.addingTimeInterval(3_600)
        let ratings: [StudyRating] = [.good, seed % 3 == 0 ? .hard : .good, .good, .easy]
        for rating in ratings.prefix(2 + seed % 3) {
            guard time < now,
                  let candidate = try? scheduler.candidates(for: card.scheduleSnapshot, at: time, desiredRetention: 0.9)[rating]
            else { break }
            let previous = card.scheduleSnapshot
            card.scheduleSnapshot = candidate.schedule
            context.insert(
                ReviewLogEntry(
                    card: card,
                    timestamp: time,
                    rating: rating,
                    previous: previous,
                    resulting: candidate.schedule,
                    elapsedInterval: candidate.elapsedDays,
                    scheduledInterval: candidate.scheduledDays
                )
            )
            time = candidate.schedule.due
        }
        switch plan {
        case .due:
            card.due = now.addingTimeInterval(-Double(seed + 1) * 3_600)
        case .later:
            card.due = now.addingTimeInterval(Double(seed + 2) * 86_400)
        case .new:
            break
        }
    }

    // MARK: - Content

    private static let englishLibrary: [DemoSubject] = [
        DemoSubject(name: "Linear Algebra", decks: [
            DemoDeck(name: "Eigen things", cards: [
                DemoCard(
                    front: "What is an **eigenvector** of a linear map $T$?",
                    back: "A non-zero vector $v$ that $T$ only stretches:\n\n$$T v = \\lambda v$$\n\nThe scalar $\\lambda$ is its eigenvalue.",
                    plan: .due
                ),
                DemoCard(
                    front: "When is a square matrix invertible?",
                    back: "Exactly when its determinant isn't zero:\n\n$$\\det A \\neq 0$$",
                    plan: .due
                ),
                DemoCard(
                    front: "The trace of a matrix equals…",
                    back: "…the sum of its eigenvalues, counted with multiplicity.",
                    plan: .later
                ),
                DemoCard(
                    front: "What does the spectral theorem promise?",
                    back: "A real symmetric matrix has an orthonormal basis of eigenvectors:\n\n$$A = Q \\Lambda Q^{\\top}$$",
                    plan: .new
                ),
            ]),
            DemoDeck(name: "Vector spaces", cards: [
                DemoCard(front: "Define a *basis*.", back: "A linearly independent set that spans the space.", plan: .due),
                DemoCard(front: "Rank–nullity theorem", back: "$$\\dim V = \\operatorname{rank} T + \\operatorname{nullity} T$$", plan: .later),
            ]),
        ]),
        DemoSubject(name: "Spanish", decks: [
            DemoDeck(name: "Everyday verbs", cards: [
                DemoCard(front: "aprovechar", back: "to make the most of\n\n> *Aprovecha el día.*", plan: .due),
                DemoCard(front: "tener", back: "to have — *tengo, tienes, tiene*", plan: .later),
                DemoCard(front: "quedar", back: "to remain; to arrange to meet\n\n- *quedamos a las ocho*\n- *no queda pan*", plan: .due),
                DemoCard(front: "echar de menos", back: "to miss someone or something", plan: .new),
                DemoCard(front: "soler", back: "to usually do — *suelo leer por la noche*", plan: .new),
            ]),
        ]),
        DemoSubject(name: "Swift", decks: [
            DemoDeck(name: "Concurrency", cards: [
                DemoCard(
                    front: "What does an `actor` protect?",
                    back: "Its mutable state — only one task touches it at a time.\n\n```swift\nactor Counter {\n    private var value = 0\n    func increment() { value += 1 }\n}\n```",
                    plan: .due
                ),
                DemoCard(front: "What makes a type `Sendable`?", back: "It is safe to share across concurrency domains without data races.", plan: .later),
                DemoCard(front: "`Task` vs `Task.detached`", back: "`Task` inherits the actor and priority it was created on; `Task.detached` inherits neither.", plan: .new),
            ]),
        ]),
        DemoSubject(name: "Biology", decks: [
            DemoDeck(name: "The cell", cards: [
                DemoCard(front: "What does ATP synthase make?", back: "**ATP**, driven by protons flowing back across the inner mitochondrial membrane.", plan: .later),
                DemoCard(front: "Where does translation happen?", back: "On ribosomes — free in the cytoplasm or on the rough ER.", plan: .later),
            ]),
        ]),
    ]

    private static let russianLibrary: [DemoSubject] = [
        DemoSubject(name: "Линейная алгебра", decks: [
            DemoDeck(name: "Собственные векторы", cards: [
                DemoCard(
                    front: "Что такое **собственный вектор** линейного оператора $T$?",
                    back: "Ненулевой вектор $v$, который $T$ только растягивает:\n\n$$T v = \\lambda v$$\n\nЧисло $\\lambda$ — его собственное значение.",
                    plan: .due
                ),
                DemoCard(
                    front: "Когда квадратная матрица обратима?",
                    back: "Ровно тогда, когда её определитель не равен нулю:\n\n$$\\det A \\neq 0$$",
                    plan: .due
                ),
                DemoCard(front: "След матрицы равен…", back: "…сумме её собственных значений с учётом кратности.", plan: .later),
                DemoCard(
                    front: "Что утверждает спектральная теорема?",
                    back: "У вещественной симметричной матрицы есть ортонормированный базис из собственных векторов:\n\n$$A = Q \\Lambda Q^{\\top}$$",
                    plan: .new
                ),
            ]),
            DemoDeck(name: "Векторные пространства", cards: [
                DemoCard(front: "Что такое *базис*?", back: "Линейно независимая система, порождающая всё пространство.", plan: .due),
                DemoCard(front: "Теорема о ранге и дефекте", back: "$$\\dim V = \\operatorname{rank} T + \\dim \\ker T$$", plan: .later),
            ]),
        ]),
        DemoSubject(name: "Испанский", decks: [
            DemoDeck(name: "Глаголы на каждый день", cards: [
                DemoCard(front: "aprovechar", back: "воспользоваться, использовать с толком\n\n> *Aprovecha el día.*", plan: .due),
                DemoCard(front: "tener", back: "иметь — *tengo, tienes, tiene*", plan: .later),
                DemoCard(front: "quedar", back: "оставаться; договориться о встрече\n\n- *quedamos a las ocho*\n- *no queda pan*", plan: .due),
                DemoCard(front: "echar de menos", back: "скучать по кому-то или чему-то", plan: .new),
                DemoCard(front: "soler", back: "обычно что-то делать — *suelo leer por la noche*", plan: .new),
            ]),
        ]),
        DemoSubject(name: "Swift", decks: [
            DemoDeck(name: "Конкурентность", cards: [
                DemoCard(
                    front: "Что защищает `actor`?",
                    back: "Своё изменяемое состояние: к нему обращается только одна задача за раз.\n\n```swift\nactor Counter {\n    private var value = 0\n    func increment() { value += 1 }\n}\n```",
                    plan: .due
                ),
                DemoCard(front: "Когда тип `Sendable`?", back: "Когда его безопасно передавать между доменами конкурентности без гонок данных.", plan: .later),
                DemoCard(front: "`Task` и `Task.detached`", back: "`Task` наследует актор и приоритет места создания, `Task.detached` — нет.", plan: .new),
            ]),
        ]),
        DemoSubject(name: "История", decks: [
            DemoDeck(name: "Книгопечатание", cards: [
                DemoCard(front: "Когда напечатана Библия Гутенберга?", back: "Около **1455** года, в Майнце.", plan: .later),
                DemoCard(front: "Первая точно датированная русская печатная книга", back: "«Апостол» Ивана Фёдорова, **1564** год.", plan: .later),
            ]),
        ]),
    ]
}
#endif
