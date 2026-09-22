import SwiftData
import SwiftUI

struct CardEditorView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case edit
        case preview
        var id: String { rawValue }
    }

    enum Side: Equatable { case front, back }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: \Deck.name) private var decks: [Deck]

    private let card: Flashcard?
    @State private var selectedDeckID: UUID?
    @State private var front: String
    @State private var back: String
    @State private var mode = Mode.edit
    @State private var showDeckPicker = false
    @FocusState private var focusedSide: Side?

    init(initialDeck: Deck, card: Flashcard? = nil) {
        self.card = card
        _selectedDeckID = State(initialValue: card?.deck?.id ?? initialDeck.id)
        _front = State(initialValue: card?.frontMarkdown ?? "")
        _back = State(initialValue: card?.backMarkdown ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            modeSwitch
            if mode == .edit { editor } else { preview }
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("done") { focusedSide = nil }
            }
        }
        .handmadeDialog(
            isPresented: $showDeckPicker,
            title: "deck",
            message: selectedDeck.map { Text(verbatim: deckLabel($0)) },
            actions: deckActions
        )
    }

    private var editorHeader: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                HandwrittenText("cancel")
                    .remnHandwrittenBounds()
            }
            .frame(minWidth: 64, minHeight: 44, alignment: .leading)

            Spacer(minLength: 4)

            HandwrittenText(card == nil ? LocalizedStringKey("card.new") : LocalizedStringKey("card.edit"))
                .font(RemnTypography.navigationTitle)
                .remnHandwrittenBounds()
                .foregroundStyle(Color.remnInk)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button(action: save) {
                HandwrittenText("save")
                    .remnHandwrittenBounds()
            }
            .frame(minWidth: 64, minHeight: 44, alignment: .trailing)
                .disabled(!canSave)
                .foregroundStyle(canSave ? Color.remnAccent : Color.remnGraphite.opacity(0.62))
        }
        .font(RemnTypography.control)
        .foregroundStyle(Color.remnAccent)
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var modeSwitch: some View {
        HStack(spacing: 0) {
            modeButton(.edit, title: "edit")
            modeButton(.preview, title: "preview")
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.remnInk.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 20)
        }
    }

    private func modeButton(_ value: Mode, title: LocalizedStringKey) -> some View {
        Button {
            focusedSide = nil
            withAnimation(.easeOut(duration: 0.16)) { mode = value }
        } label: {
            HandwrittenText(title)
                .font(
                    RemnTypography.display(
                        19,
                        weight: mode == value ? .semibold : .regular,
                        relativeTo: .body
                    )
                )
                .remnHandwrittenBounds(horizontal: 3, vertical: 1)
                .foregroundStyle(mode == value ? Color.remnAccent : Color.remnGraphite)
                .frame(maxWidth: .infinity, minHeight: 46)
                .contentShape(Rectangle())
                .overlay(alignment: .bottom) {
                    if mode == value {
                        Rectangle()
                            .fill(Color.remnAccent)
                            .frame(height: 2)
                            .padding(.horizontal, 18)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                deckMenu
                MarkdownToolbar(insert: insert)
                editorSection(title: "card.front", text: $front, side: .front)
                editorSection(title: "card.back", text: $back, side: .back)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var deckMenu: some View {
        Button { showDeckPicker = true } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HandwrittenText("deck")
                        .font(RemnTypography.smallControl)
                        .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                        .foregroundStyle(Color.remnGraphite)
                    if let selectedDeck {
                        HandwrittenText(verbatim: selectedDeck.name)
                            .font(RemnTypography.display(22, weight: .medium, relativeTo: .body))
                            .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                            .foregroundStyle(Color.remnInk)
                            .lineLimit(1)
                        if let subject = selectedDeck.subject {
                            HandwrittenText(verbatim: subject.name)
                                .font(RemnTypography.smallControl)
                                .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                                .foregroundStyle(Color.remnGraphite)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 8)
                DoodleIcon(kind: .down, color: .remnGraphite, size: 18)
                    .frame(width: 44, height: 44)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
            .overlay(alignment: .bottom) {
                ScribbleDivider(seed: 204)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("deck"))
    }

    private var deckActions: [HandmadeDialogAction] {
        decks.map { deck in
            HandmadeDialogAction(
                verbatim: deckLabel(deck),
                role: selectedDeckID == deck.id ? .normal : .plain
            ) {
                selectedDeckID = deck.id
                showDeckPicker = false
            }
        } + [
            HandmadeDialogAction("cancel", role: .cancel) { showDeckPicker = false }
        ]
    }

    private var preview: some View {
        ScrollView {
            FlashcardSurface(seed: card?.id.hashValue ?? 88) {
                VStack(alignment: .leading, spacing: 12) {
                    FlashcardSideLabel(title: "card.front")
                    CardContentView(markdown: front, context: .preview)
                    ScribbleDivider(seed: 88)
                    FlashcardSideLabel(title: "card.back")
                    CardContentView(markdown: back, context: .preview)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 44)
        }
    }

    private func editorSection(title: LocalizedStringKey, text: Binding<String>, side: Side) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HandwrittenText(title)
                .font(RemnTypography.display(21, weight: .medium, relativeTo: .headline))
                .remnHandwrittenBounds(horizontal: 3, vertical: 1)
                .foregroundStyle(focusedSide == side ? Color.remnAccent : Color.remnGraphite)

            ZStack(alignment: .topLeading) {
                WobblyRoundedRectangle(seed: side == .front ? 141 : 177, cornerRadius: 12)
                    .fill(Color.remnSurface)

                if text.wrappedValue.isEmpty {
                    Text(side == .front ? "editor.front.placeholder" : "editor.back.placeholder")
                        .font(.system(.body, design: .default))
                        .foregroundStyle(Color.remnGraphite.opacity(0.7))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 15)
                        .allowsHitTesting(false)
                }

                TextEditor(text: text)
                    .focused($focusedSide, equals: side)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color.remnInk)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
            }
            .frame(height: side == .front ? 176 : 204)
            .overlay {
                WobblyRoundedRectangle(seed: side == .front ? 141 : 177, cornerRadius: 12)
                    .stroke(
                        focusedSide == side ? Color.remnAccent : Color.remnInk.opacity(0.16),
                        lineWidth: focusedSide == side ? 1.6 : 1
                    )
            }
            .animation(.easeOut(duration: 0.12), value: focusedSide)
            .onTapGesture { focusedSide = side }
        }
    }

    private var canSave: Bool {
        selectedDeckID != nil
            && !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func insert(_ insertion: MarkdownInsertion) {
        let value = insertion.template
        if focusedSide == .back {
            if !back.isEmpty { back += "\n" }
            back += value
        } else {
            if !front.isEmpty { front += "\n" }
            front += value
            focusedSide = .front
        }
    }

    private func save() {
        guard let deck = decks.first(where: { $0.id == selectedDeckID }) else { return }
        if let card {
            card.deck = deck
            card.frontMarkdown = front
            card.backMarkdown = back
            card.updatedAt = .now
        } else {
            context.insert(Flashcard(deck: deck, frontMarkdown: front, backMarkdown: back))
        }
        do {
            try context.save()
            dismiss()
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func deckLabel(_ deck: Deck) -> String {
        if let subject = deck.subject { return "\(subject.name) / \(deck.name)" }
        return deck.name
    }

    private var selectedDeck: Deck? {
        decks.first { $0.id == selectedDeckID }
    }
}
