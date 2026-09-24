import Foundation
import Observation
import SwiftUI

/// Something asked for from a menu or a keyboard shortcut, handled by whichever view owns it.
enum AppCommand: Equatable {
    case newSubject
    case newCard
    case search
}

@MainActor
@Observable
final class AppState {
    var presentedSession: StudySessionRecord?
    var errorMessage: String?
    var showStudySetup = false
    var preselectedSubjectIDs: Set<UUID> = []
    var preselectedDeckID: UUID?
    var requestedCommand: AppCommand?

    /// The subject and deck on screen, so a new card lands where you're looking.
    var currentSubjectID: UUID?
    var currentDeckID: UUID?

    func prepareStudy(subjectIDs: Set<UUID> = [], deckID: UUID? = nil) {
        preselectedSubjectIDs = subjectIDs
        preselectedDeckID = deckID
        showStudySetup = true
    }
}

extension FocusedValues {
    /// The state of the window in front, for menu commands.
    @Entry var remnAppState: AppState?
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: SwiftUI.ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
