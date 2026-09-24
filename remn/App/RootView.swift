import SwiftData
import SwiftUI

struct RootView: View {
    @State private var appState = AppState()

    var body: some View {
        NavigationStack {
            LibraryView()
        }
        .environment(appState)
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
}
