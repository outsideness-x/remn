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
    @State private var flipScaleX: CGFloat = 1
    @State private var flipLift: CGFloat = 0
    @State private var isFlipping = false
    @State private var ratingsVisible = false
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
            .handmadeDialog(
                isPresented: $showRatingsHelp,
                title: "study.ratingsHelp.title",
                message: Text("study.ratingsHelp.message"),
                actions: [HandmadeDialogAction("ok") {}]
            )
            .onAppear(perform: prepareQueue)
        }
        .background(Color.remnPaper.ignoresSafeArea())
    }

    private var studyHeader: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                HandwrittenText("close")
                    .remnHandwrittenBounds()
            }
            .frame(minWidth: 64, minHeight: 44, alignment: .leading)
            Spacer()
            HandwrittenText(verbatim: session.isActive ? progress : "remn")
                .font(session.isActive ? .caption.monospacedDigit() : RemnTypography.navigationTitle)
                .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                .foregroundStyle(Color.remnGraphite)
            Spacer()
            Group {
                if showUndo {
                    Button(action: undo) {
                        HandwrittenText("undo")
                            .remnHandwrittenBounds()
                    }
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
                HandwrittenText(verbatim: card.deckContext)
                    .font(RemnTypography.smallControl)
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                    .foregroundStyle(Color.remnGraphite)
                studyCardFace(card, isBack: showingBack)
                .scaleEffect(x: reduceMotion ? 1 : flipScaleX, y: 1, anchor: .center)
                .offset(y: reduceMotion ? 0 : flipLift)
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
            if revealed {
                ratings(for: card)
                    .opacity(ratingsVisible ? 1 : 0)
                    .offset(y: ratingsVisible ? 0 : 8)
                    .allowsHitTesting(ratingsVisible)
            }
        }
    }

    private func studyCardFace(_ card: Flashcard, isBack: Bool) -> some View {
        FlashcardSurface(
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
                    DoodleIcon(kind: .flip, color: .remnGraphite, size: 18)
                    HandwrittenText(isBack ? "study.tapFlip" : "study.tapReveal")
                        .font(RemnTypography.smallControl)
                        .remnHandwrittenBounds(horizontal: 3, vertical: 1)
                }
                .foregroundStyle(Color.remnGraphite)
            }
        }
    }

    private func revealOrFlip(_ card: Flashcard) {
        guard !isFlipping else { return }

        if revealed {
            flipCard(toBack: !showingBack)
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
            ratingsVisible = false
            flipCard(toBack: true) {
                withAnimation(.easeOut(duration: 0.18)) {
                    ratingsVisible = true
                }
                if needsHelp {
                    showRatingsHelp = true
                }
            }
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func flipCard(toBack: Bool, completion: (() -> Void)? = nil) {
        guard showingBack != toBack else {
            completion?()
            return
        }

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.15)) {
                showingBack = toBack
            }
            completion?()
            return
        }

        isFlipping = true
        withAnimation(.timingCurve(0.42, 0, 0.78, 0.38, duration: 0.16)) {
            flipScaleX = 0.035
            flipLift = -3
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            showingBack = toBack

            withAnimation(.timingCurve(0.18, 0.72, 0.20, 1, duration: 0.23)) {
                flipScaleX = 1
                flipLift = 0
            }

            try? await Task.sleep(for: .milliseconds(230))
            isFlipping = false
            completion?()
        }
    }

    private func ratings(for card: Flashcard) -> some View {
        VStack(spacing: 8) {
            HStack {
                HandwrittenText("study.rate")
                    .font(RemnTypography.smallControl)
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
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
            ratingsVisible = false
            flipScaleX = 1
            flipLift = 0
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
            ratingsVisible = false
            flipScaleX = 1
            flipLift = 0
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
