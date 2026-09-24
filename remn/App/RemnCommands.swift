import SwiftUI

/// The menu bar on the Mac, and the shortcuts a hardware keyboard shows on iPad.
struct RemnCommands: Commands {
    @FocusedValue(\.remnAppState) private var appState

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("menu.settings") { appState?.showsSettings = true }
                .keyboardShortcut(",")
                .disabled(appState == nil)
        }
        CommandGroup(replacing: .newItem) {
            if appState?.section == .notes {
                Button("menu.newNote") { appState?.requestedCommand = .newNote }
                    .keyboardShortcut("n")
                Button("menu.newFolder") { appState?.requestedCommand = .newFolder }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            } else {
                Button("menu.newCard") { appState?.requestedCommand = .newCard }
                    .keyboardShortcut("n")
                    .disabled(appState == nil)
                Button("menu.newSubject") { appState?.requestedCommand = .newSubject }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                    .disabled(appState == nil)
            }
        }
        CommandGroup(before: .sidebar) {
            Button("menu.showCards") { appState?.section = .cards }
                .keyboardShortcut("1")
                .disabled(appState == nil)
            Button("menu.showNotes") { appState?.section = .notes }
                .keyboardShortcut("2")
                .disabled(appState == nil)
            Divider()
        }
        CommandGroup(after: .textEditing) {
            Button(appState?.section == .notes ? "menu.searchNotes" : "menu.search") { appState?.requestedCommand = .search }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(appState == nil)
        }
        CommandMenu("menu.study") {
            Button("menu.startStudying") { appState?.prepareStudy() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState == nil || appState?.presentedSession != nil)
        }
    }
}
