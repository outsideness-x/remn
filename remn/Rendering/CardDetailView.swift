import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Bindable var card: Flashcard

    @State private var showEditor = false
    @State private var showActions = false
    @State private var showDelete = false
    @State private var showReset = false
    @State private var isExporting = false
    @State private var exportMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(title: "card") {
                Button { showActions = true } label: {
                    DoodleIcon(kind: .more, color: .remnInk, size: 21)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("actions"))
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HandwrittenText(verbatim: card.deckContext)
                        .font(RemnTypography.smallControl)
                        .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                        .foregroundStyle(Color.remnGraphite)
                    FlashcardSurface(seed: card.id.hashValue) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline) {
                                FlashcardSideLabel(title: "card.front")
                                Spacer()
                                HandwrittenText(verbatim: RemnFormatters.dueStatus(for: card))
                                    .font(RemnTypography.smallControl)
                                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                                    .foregroundStyle(Color.remnGraphite)
                            }
                            CardContentView(markdown: card.frontMarkdown)
                            ScribbleDivider(seed: card.id.hashValue)
                            FlashcardSideLabel(title: "card.back")
                            CardContentView(markdown: card.backMarkdown)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 44)
            }
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                    VStack(spacing: 8) {
                        StackedCardsDoodle()
                            .scaleEffect(0.72)
                            .frame(width: 42, height: 34)
                        HandwrittenText("export.saving")
                            .font(RemnTypography.control)
                            .remnHandwrittenBounds()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 17)
                    .background {
                        WobblyRoundedRectangle(seed: 688, cornerRadius: 12)
                            .fill(Color.remnCardPaper)
                    }
                    .overlay {
                        WobblyRoundedRectangle(seed: 688, cornerRadius: 12)
                            .stroke(Color.remnInk.opacity(0.72), lineWidth: 1.2)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let deck = card.deck { CardEditorView(initialDeck: deck, card: card) }
        }
        .handmadeDialog(
            isPresented: $showActions,
            title: "card",
            message: Text(verbatim: RemnFormatters.usefulLine(card.frontMarkdown)),
            actions: cardActions
        )
        .handmadeDialog(
            isPresented: $showDelete,
            title: "card.delete.title",
            message: Text("card.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    context.delete(card)
                    do { try context.save(); dismiss() }
                    catch { appState.errorMessage = error.localizedDescription }
                },
                HandmadeDialogAction("cancel", role: .cancel) {}
            ]
        )
        .handmadeDialog(
            isPresented: $showReset,
            title: "card.reset.title",
            message: Text("card.reset.message"),
            actions: [
                HandmadeDialogAction("card.reset", role: .destructive) {
                    do { try ReviewService().reset(card, context: context) }
                    catch { appState.errorMessage = error.localizedDescription }
                },
                HandmadeDialogAction("cancel", role: .cancel) {}
            ]
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { exportMessage != nil },
                set: { if !$0 { exportMessage = nil } }
            ),
            title: "export.result",
            message: Text(verbatim: exportMessage ?? ""),
            actions: [
                HandmadeDialogAction("ok") { exportMessage = nil }
            ]
        )
    }

    private func duplicate() {
        guard let deck = card.deck else { return }
        context.insert(
            Flashcard(deck: deck, frontMarkdown: card.frontMarkdown, backMarkdown: card.backMarkdown)
        )
        do { try context.save() }
        catch { appState.errorMessage = error.localizedDescription }
    }

    private var cardActions: [HandmadeDialogAction] {
        [
            HandmadeDialogAction("edit", role: .plain) {
                showActions = false
                showEditor = true
            },
            HandmadeDialogAction("card.duplicate", role: .plain, perform: duplicate),
            HandmadeDialogAction("card.saveImage", role: .plain, perform: export),
            HandmadeDialogAction("card.reset", role: .plain) {
                showActions = false
                showReset = true
            },
            HandmadeDialogAction("delete", role: .destructive) {
                showActions = false
                showDelete = true
            },
            HandmadeDialogAction("cancel", role: .cancel) { showActions = false }
        ]
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
