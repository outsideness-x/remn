import SwiftData
import SwiftUI

struct StudySessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var cards: [Flashcard]
    @AppStorage("desiredRetention") private var desiredRetention = 0.90
    @AppStorage("didShowRatingHelp") private var didShowRatingHelp = false

    @Bindable var session: StudySessionRecord
    @State private var revealed = false
    @State private var candidates: [StudyRating: ScheduleCandidate] = [:]
    @State private var reviewTime = Date()
    @State private var showRatingsHelp = false
    @State private var showUndo = false

    var body: some View {
        VStack(spacing: 0) {
            studyHeader
            Group {
                if session.isActive, let card = currentCard {
                    study(card)
                } else {
                    StudyCompletionView(session: session)
                }
            }
            .background(Color.remnPaper.ignoresSafeArea())
            .alert("study.ratingsHelp.title", isPresented: $showRatingsHelp) {
                Button("ok", role: .cancel) {}
            } message: {
                Text("study.ratingsHelp.message")
            }
            .onAppear(perform: prepareQueue)
        }
        .background(Color.remnPaper.ignoresSafeArea())
    }

    private var studyHeader: some View {
        HStack(spacing: 8) {
            Button("close") { dismiss() }
                .frame(minWidth: 64, minHeight: 44, alignment: .leading)
            Spacer()
            Text(session.isActive ? progress : "remn")
                .font(session.isActive ? .caption.monospacedDigit() : RemnTypography.navigationTitle)
                .foregroundStyle(Color.remnGraphite)
            Spacer()
            Group {
                if showUndo {
                    Button("undo", action: undo)
                        .transition(.opacity)
                } else {
                    Color.clear
                }
            }
            .frame(width: 64, height: 44, alignment: .trailing)
        }
        .font(RemnTypography.control)
        .foregroundStyle(Color.remnAccent)
        .buttonStyle(.plain)
        .padding(.horizontal, 22)
        .padding(.vertical, 6)
        .background(Color.remnPaper)
    }

    private func study(_ card: Flashcard) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(card.deckContext)
                    .font(RemnTypography.smallControl)
                    .foregroundStyle(Color.remnGraphite)
                FlashcardSurface(seed: card.id.hashValue, style: .study) {
                    VStack(alignment: .leading, spacing: 19) {
                        FlashcardSideLabel(title: "card.front")
                        CardContentView(markdown: card.frontMarkdown, context: .study)
                        if revealed {
                            ScribbleDivider(seed: card.id.hashValue)
                                .padding(.vertical, 3)
                            FlashcardSideLabel(title: "card.back")
                            CardContentView(markdown: card.backMarkdown, context: .study)
                                .transition(.opacity.combined(with: reduceMotion ? .identity : .move(edge: .top)))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, revealed ? 100 : 76)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: revealed)
        }
        .safeAreaInset(edge: .bottom) {
            if revealed { ratings(for: card) } else { revealButton(card) }
        }
    }

    private func revealButton(_ card: Flashcard) -> some View {
        Button {
            reviewTime = .now
            do {
                candidates = try ReviewService().candidates(
                    for: card,
                    at: reviewTime,
                    desiredRetention: desiredRetention
                )
                revealed = true
                if !didShowRatingHelp {
                    didShowRatingHelp = true
                    showRatingsHelp = true
                }
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        } label: {
            Text("study.showAnswer").frame(maxWidth: .infinity)
        }
        .buttonStyle(WobblyButtonStyle(filled: true, seed: card.id.hashValue))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.remnPaper.opacity(0.97))
    }

    private func ratings(for card: Flashcard) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("study.rate")
                    .font(.caption)
                    .foregroundStyle(Color.remnGraphite)
                Spacer()
                Button { showRatingsHelp = true } label: {
                    Image(systemName: "info.circle").frame(width: 44, height: 32)
                }
                .accessibilityLabel(Text("study.ratingsHelp.title"))
            }
            HStack(spacing: 7) {
                ForEach(StudyRating.allCases) { rating in
                    if let candidate = candidates[rating] {
                        RatingButton(
                            rating: rating,
                            interval: RemnFormatters.interval(from: reviewTime, to: candidate.schedule.due)
                        ) {
                            grade(rating, candidate: candidate, card: card)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 5)
        .padding(.bottom, 9)
        .background(Color.remnPaper.opacity(0.97))
    }

    private var currentCard: Flashcard? {
        guard let id = session.queueCardIDs.first else { return nil }
        return cards.first { $0.id == id }
    }

    private var progress: String {
        "\(min(session.reviewedCount + 1, session.admittedCardIDs.count))/\(session.admittedCardIDs.count)"
    }

    private func grade(_ rating: StudyRating, candidate: ScheduleCandidate, card: Flashcard) {
        do {
            try ReviewService().apply(
                rating,
                candidate: candidate,
                to: card,
                in: session,
                context: context,
                at: reviewTime
            )
            revealed = false
            candidates = [:]
            SessionService.refreshQueue(session, cards: cards)
            try context.save()
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { showUndo = true }
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func undo() {
        do {
            try ReviewService().undoLastReview(in: session, context: context)
            revealed = false
            candidates = [:]
            withAnimation { showUndo = false }
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func prepareQueue() {
        let existingIDs = Set(cards.map(\.id))
        session.queueCardIDs.removeAll { !existingIDs.contains($0) }
        SessionService.refreshQueue(session, cards: cards)
        try? context.save()
    }
}
