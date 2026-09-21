import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Bindable var card: Flashcard

    @State private var showEditor = false
    @State private var showDelete = false
    @State private var showReset = false
    @State private var isExporting = false
    @State private var exportMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(title: "card") {
                Menu {
                    Button("edit") { showEditor = true }
                    Button("card.duplicate", action: duplicate)
                    Button("card.saveImage", action: export)
                    Button("card.reset") { showReset = true }
                    Divider()
                    Button("delete", role: .destructive) { showDelete = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text(card.deckContext)
                        .font(RemnTypography.smallControl)
                        .foregroundStyle(Color.remnGraphite)
                    CardContentView(markdown: card.frontMarkdown)
                    ScribbleDivider(seed: card.id.hashValue)
                        .padding(.vertical, 4)
                    CardContentView(markdown: card.backMarkdown)
                }
                .padding(.horizontal, 26)
                .padding(.top, 28)
                .padding(.bottom, 44)
            }
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if isExporting {
                ProgressView("export.saving")
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .sheet(isPresented: $showEditor) {
            if let deck = card.deck { CardEditorView(initialDeck: deck, card: card) }
        }
        .confirmationDialog("card.delete.title", isPresented: $showDelete, titleVisibility: .visible) {
            Button("delete", role: .destructive) {
                context.delete(card)
                do { try context.save(); dismiss() }
                catch { appState.errorMessage = error.localizedDescription }
            }
            Button("cancel", role: .cancel) {}
        } message: { Text("card.delete.message") }
        .confirmationDialog("card.reset.title", isPresented: $showReset, titleVisibility: .visible) {
            Button("card.reset", role: .destructive) {
                do { try ReviewService().reset(card, context: context) }
                catch { appState.errorMessage = error.localizedDescription }
            }
            Button("cancel", role: .cancel) {}
        } message: { Text("card.reset.message") }
        .alert(
            "export.result",
            isPresented: Binding(
                get: { exportMessage != nil },
                set: { if !$0 { exportMessage = nil } }
            )
        ) {
            Button("ok", role: .cancel) { exportMessage = nil }
        } message: { Text(exportMessage ?? "") }
    }

    private func duplicate() {
        guard let deck = card.deck else { return }
        context.insert(
            Flashcard(deck: deck, frontMarkdown: card.frontMarkdown, backMarkdown: card.backMarkdown)
        )
        do { try context.save() }
        catch { appState.errorMessage = error.localizedDescription }
    }

    private func export() {
        isExporting = true
        Task { @MainActor in
            defer { isExporting = false }
            do {
                try await CardImageExporter.save(card)
                exportMessage = RemnLanguage.localized("export.saved")
            } catch {
                exportMessage = error.localizedDescription
            }
        }
    }
}
