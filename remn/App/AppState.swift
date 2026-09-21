import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppState {
    var presentedSession: StudySessionRecord?
    var errorMessage: String?
    var showStudySetup = false
    var preselectedSubjectIDs: Set<UUID> = []
    var preselectedDeckID: UUID?

    func prepareStudy(subjectIDs: Set<UUID> = [], deckID: UUID? = nil) {
        preselectedSubjectIDs = subjectIDs
        preselectedDeckID = deckID
        showStudySetup = true
    }
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
