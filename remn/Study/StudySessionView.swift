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
    @State private var showingBack = false
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
                ZStack(alignment: .topLeading) {
                    studyCardFace(card, isBack: false)
                    studyCardFace(card, isBack: true)
                }
                .contentShape(Rectangle())
                .onTapGesture { revealOrFlip(card) }
                .accessibilityHint(Text(showingBack ? "study.tapFlip" : "study.tapReveal"))
                .accessibilityAction(named: Text(showingBack ? "card.front" : "card.back")) {
                    revealOrFlip(card)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, revealed ? 100 : 40)
        }
        .safeAreaInset(edge: .bottom) {
            if revealed { ratings(for: card) }
        }
    }

    private func studyCardFace(_ card: Flashcard, isBack: Bool) -> some View {
        let isVisible = showingBack == isBack
        let angle = isBack
            ? (showingBack ? 0.0 : 90.0)
            : (showingBack ? -90.0 : 0.0)

        return FlashcardSurface(
            seed: card.id.hashValue &+ (isBack ? 1 : 0),
            style: .study
        ) {
            VStack(alignment: .leading, spacing: 19) {
                FlashcardSideLabel(title: isBack ? "card.back" : "card.front")
                CardContentView(
                    markdown: isBack ? card.backMarkdown : card.frontMarkdown,
                    context: .study
                )
                HStack(spacing: 7) {
                    Spacer()
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2.weight(.semibold))
                    Text(isBack ? "study.tapFlip" : "study.tapReveal")
                        .font(RemnTypography.smallControl)
                }
                .foregroundStyle(Color.remnGraphite)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : angle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.58
        )
        .zIndex(isVisible ? 1 : 0)
        .accessibilityHidden(!isVisible)
        .animation(
            reduceMotion ? .easeOut(duration: 0.15) : .easeInOut(duration: 0.40),
            value: showingBack
        )
    }

    private func revealOrFlip(_ card: Flashcard) {
        if revealed {
            showingBack.toggle()
            return
        }

        reviewTime = .now
        do {
            candidates = try ReviewService().candidates(
                for: card,
                at: reviewTime,
                desiredRetention: desiredRetention
            )
            let needsHelp = !didShowRatingHelp
            didShowRatingHelp = true
            revealed = true
            showingBack = true

            if needsHelp {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(reduceMotion ? 180 : 460))
                    showRatingsHelp = true
                }
            }
        } catch {
            appState.errorMessage = error.localizedDescription
        }
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
            showingBack = false
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
            showingBack = false
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
