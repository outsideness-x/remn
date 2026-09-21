import SwiftUI

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
            HStack(spacing: 8) {
                Button { dismiss() } label: {
                    HandwrittenText("cancel")
                        .remnHandwrittenBounds()
                }
                .frame(minWidth: 64, minHeight: 44, alignment: .leading)
                Spacer(minLength: 4)
                HandwrittenText(title)
                    .font(RemnTypography.navigationTitle)
                    .remnHandwrittenBounds()
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Button(action: save) {
                    HandwrittenText(actionTitle)
                        .remnHandwrittenBounds()
                }
                .frame(minWidth: 64, minHeight: 44, alignment: .trailing)
                    .disabled(cleanName.isEmpty)
                    .opacity(cleanName.isEmpty ? 0.35 : 1)
            }
            .font(RemnTypography.control)
            .foregroundStyle(Color.remnAccent)
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 22) {
                TextField("name", text: $name)
                    .font(.system(.title2, design: .default, weight: .medium))
                    .textFieldStyle(.plain)
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) {
                        ScribbleDivider(seed: 41)
                    }
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(save)
                Spacer()
            }
            .padding(24)
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .onAppear { isFocused = true }
        .presentationDetents([.height(220)])
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
