import SwiftData
import SwiftUI

struct StudyCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    let session: StudySessionRecord

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            StackedCardsDoodle()
            Text("done.")
                .font(RemnTypography.display(42, weight: .medium, relativeTo: .largeTitle))
                .remnHandwrittenBounds()
                .foregroundStyle(Color.remnInk)
            Text(summary)
                .font(.callout.monospacedDigit())
                .foregroundStyle(Color.remnGraphite)
            Spacer()
            Button("study.backLibrary") {
                session.isActive = false
                try? context.save()
                appState.presentedSession = nil
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(WobblyButtonStyle(filled: true, seed: 63))
            Button("study.more") {
                session.isActive = false
                try? context.save()
                appState.presentedSession = nil
                dismiss()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    appState.prepareStudy(subjectIDs: Set(session.subjectIDs), deckID: session.deckID)
                }
            }
            .buttonStyle(.plain)
            .font(RemnTypography.control)
            .remnHandwrittenBounds()
        }
        .padding(24)
        .background(Color.remnPaper.ignoresSafeArea())
    }

    private var summary: String {
        let reviews = max(0, session.admittedCardIDs.count - session.initialNewCount)
        return "\(session.admittedCardIDs.count) \(RemnLanguage.localized("library.cards"))  ·  \(session.initialNewCount) \(RemnLanguage.localized("status.new"))  ·  \(reviews) \(RemnLanguage.localized("study.reviews"))"
    }
}
