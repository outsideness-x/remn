import SwiftUI

/// Naming a subject or a deck: one line to write on.
struct NameEditorSheet: View {
    let title: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let initialValue: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @FocusState private var isFocused: Bool

    init(
        title: LocalizedStringKey,
        actionTitle: LocalizedStringKey = "save",
        initialValue: String = "",
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.initialValue = initialValue
        self.onSave = onSave
        _name = State(initialValue: initialValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: title) {
                dismiss()
            } trailing: {
                Button(action: save) {
                    HandwrittenText(actionTitle, weight: 0.4)
                }
                .buttonStyle(InkButtonStyle(kind: .quiet, seed: 14))
                .disabled(cleanName.isEmpty)
                .opacity(cleanName.isEmpty ? 0.4 : 1)
            }

            TextField("name", text: $name)
                .font(RemnTypography.display(28, relativeTo: .title2))
                .foregroundStyle(Color.remnInk)
                .tint(.remnAccent)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit(save)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    InkLine(seed: 41, pen: .fine)
                        .fill(Color.remnInk.opacity(0.55))
                        .frame(height: 6)
                        .offset(y: 2)
                }
                .padding(.horizontal, 26)
                .padding(.top, 22)
            Spacer(minLength: 0)
        }
        .paperBackground()
        .onAppear { isFocused = true }
        .presentationDetents([.height(210)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
    }

    private var cleanName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !cleanName.isEmpty else { return }
        onSave(cleanName)
        dismiss()
    }
}
