import SwiftData
import SwiftUI

struct RootView: View {
    @State private var appState = AppState()
    @Query(sort: [SortDescriptor(\Deck.manualSortOrder), SortDescriptor(\Deck.createdAt)])
    private var decks: [Deck]
    @State private var newCardDeck: Deck?

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        Group {
            if usesSplitLayout {
                LibrarySplitView()
            } else {
                NavigationStack {
                    LibraryView()
                }
            }
        }
        .environment(appState)
        .focusedSceneValue(\.remnAppState, appState)
        .onChange(of: appState.requestedCommand) { _, command in
            guard command == .newCard else { return }
            appState.requestedCommand = nil
            newCardDeck = deckForNewCard
        }
        .sheet(isPresented: $appState.showStudySetup) {
            StudySetupSheet(
                initialSubjectIDs: appState.preselectedSubjectIDs,
                initialDeckID: appState.preselectedDeckID
            ) { session in
                appState.showStudySetup = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    appState.presentedSession = session
                }
            }
            .environment(appState)
        }
        .sheet(item: $newCardDeck) { deck in
            CardEditorView(initialDeck: deck)
                .environment(appState)
        }
        .remnFullScreenCover(
            isPresented: Binding(
                get: { appState.presentedSession != nil },
                set: { if !$0 { appState.presentedSession = nil } }
            )
        ) {
            if let session = appState.presentedSession {
                StudySessionView(session: session)
                    .environment(appState)
            }
        }
        .handmadeDialog(
            isPresented: Binding(
                get: { appState.errorMessage != nil },
                set: { if !$0 { appState.errorMessage = nil } }
            ),
            title: "error",
            message: Text(verbatim: appState.errorMessage ?? ""),
            actions: [
                HandmadeDialogAction("ok") { appState.errorMessage = nil }
            ]
        )
    }

    /// iPhone gets one page at a time; iPad and the Mac get the library beside what's open.
    private var usesSplitLayout: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    /// The deck on screen, else the first deck of the subject on screen, else the first deck there is.
    private var deckForNewCard: Deck? {
        if let id = appState.currentDeckID, let deck = decks.first(where: { $0.id == id }) {
            return deck
        }
        if let id = appState.currentSubjectID,
           let deck = decks.first(where: { $0.subject?.id == id }) {
            return deck
        }
        return decks.first
    }
}

/// The library as a sidebar with a pencil rule down its edge, and whatever you chose beside it.
struct LibrarySplitView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: [SortDescriptor(\SubjectModel.manualSortOrder), SortDescriptor(\SubjectModel.createdAt)])
    private var subjects: [SubjectModel]
    @State private var selection: LibraryDestination?

    var body: some View {
        HStack(spacing: 0) {
            LibraryView(selection: $selection)
                .frame(width: RemnPlatform.isMac ? 300 : 330)
            InkLine(seed: 7_001, pen: .hairline, vertical: true)
                .fill(Color.remnInk.opacity(0.28))
                .frame(width: 6)
                .padding(.vertical, 18)
                .background { PaperBackground() }
                .accessibilityHidden(true)
            NavigationStack {
                detail
                    .environment(\.remnIsNavigationRoot, true)
            }
            .id(selection)
            .padding(.top, RemnPlatform.isMac ? 22 : 0)
            .background { PaperBackground() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: chooseFirstSubjectIfNeeded)
        .onChange(of: subjects.map(\.id)) { _, _ in chooseFirstSubjectIfNeeded() }
        .onChange(of: appState.requestedCommand) { _, command in
            guard command == .search else { return }
            appState.requestedCommand = nil
            selection = .search
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .subject(let id):
            if let subject = subjects.first(where: { $0.id == id }) {
                SubjectDetailView(subject: subject)
            } else {
                placeholder
            }
        case .search:
            SearchView()
        case .settings:
            SettingsView()
        case nil:
            placeholder
        }
    }

    private var placeholder: some View {
        VStack(spacing: 22) {
            StackedCardsDoodle(width: 92)
            HandwrittenText("library.pickSubject")
                .font(RemnTypography.sectionTitle)
                .foregroundStyle(Color.remnGraphite)
                .multilineTextAlignment(.center)
        }
        .inkWritesOn(duration: 0.8)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paperBackground()
        .remnHidesSystemBar()
    }

    private func chooseFirstSubjectIfNeeded() {
        if case .subject(let id) = selection, subjects.contains(where: { $0.id == id }) { return }
        if selection == .search || selection == .settings { return }
        selection = subjects.first.map { .subject($0.id) }
    }
}
