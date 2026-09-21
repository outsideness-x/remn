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
                Menu("editor.insert") {
                    ForEach(MarkdownInsertion.allCases) { insertion in
                        Button(insertion.localizedLabel) { insert(insertion) }
                    }
                }
                Spacer()
                Button("done") { focusedSide = nil }
            }
        }
    }

    private var editorHeader: some View {
        HStack(spacing: 8) {
            Button("cancel") { dismiss() }
                .frame(minWidth: 64, minHeight: 44, alignment: .leading)

            Spacer(minLength: 4)

            Text(card == nil ? LocalizedStringKey("card.new") : LocalizedStringKey("card.edit"))
                .font(RemnTypography.navigationTitle)
                .foregroundStyle(Color.remnInk)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button("save", action: save)
                .frame(minWidth: 64, minHeight: 44, alignment: .trailing)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.35)
        }
        .font(RemnTypography.control)
        .foregroundStyle(Color.remnAccent)
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 18)
    }

    private var modeSwitch: some View {
        HStack(spacing: 40) {
            modeButton(.edit, title: "edit")
            modeButton(.preview, title: "preview")
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 22)
    }

    private func modeButton(_ value: Mode, title: LocalizedStringKey) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.16)) { mode = value }
        } label: {
            Text(title)
                .font(
                    RemnTypography.display(
                        18,
                        weight: mode == value ? .semibold : .regular,
                        relativeTo: .body
                    )
                )
                .foregroundStyle(mode == value ? Color.remnAccent : Color.remnGraphite)
                .frame(minWidth: 82, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("deck")
                        .font(RemnTypography.control)
                        .foregroundStyle(Color.remnGraphite)
                    Spacer()
                    Picker("deck", selection: $selectedDeckID) {
                        ForEach(decks, id: \.id) { deck in
                            Text(deckLabel(deck)).tag(Optional(deck.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.body.weight(.medium))
                    .tint(.remnInk)
                }
                MarkdownToolbar(insert: insert)
                editorSection(title: "card.front", text: $front, side: .front)
                editorSection(title: "card.back", text: $back, side: .back)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var preview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {
                Text("card.front")
                    .font(RemnTypography.control)
                    .foregroundStyle(Color.remnGraphite)
                CardContentView(markdown: front, context: .preview)
                ScribbleDivider(seed: 88)
                Text("card.back")
                    .font(RemnTypography.control)
                    .foregroundStyle(Color.remnGraphite)
                CardContentView(markdown: back, context: .preview)
            }
            .padding(.horizontal, 26)
            .padding(.top, 28)
            .padding(.bottom, 44)
        }
    }

    private func editorSection(title: LocalizedStringKey, text: Binding<String>, side: Side) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(RemnTypography.display(19, weight: .medium, relativeTo: .headline))
                .foregroundStyle(Color.remnGraphite)
            TextEditor(text: text)
                .focused($focusedSide, equals: side)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, -5)
                .padding(.vertical, 4)
                .frame(minHeight: 188)
                .overlay(alignment: .bottom) {
                    ScribbleDivider(seed: side == .front ? 141 : 177)
                }
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
}
