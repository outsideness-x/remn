import SwiftUI

/// The menu bar on the Mac, and the shortcuts a hardware keyboard shows on iPad.
struct RemnCommands: Commands {
    @FocusedValue(\.remnAppState) private var appState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("menu.newCard") { appState?.requestedCommand = .newCard }
                .keyboardShortcut("n")
                .disabled(appState == nil)
            Button("menu.newSubject") { appState?.requestedCommand = .newSubject }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(appState == nil)
        }
        CommandGroup(after: .textEditing) {
            Button("menu.search") { appState?.requestedCommand = .search }
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
