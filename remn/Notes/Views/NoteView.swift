import SwiftUI

/// One note, open: its title, its tags and the live editor, saved to its file as you write.
struct NoteView: View {
    @Environment(Vault.self) private var vault
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var path: String
    @State private var title: String
    @State private var document = NoteDocument()
    @State private var controller = LiveEditorController(font: .default)
    @State private var isLoaded = false
    @State private var savedText = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var loadError: String?

    @State private var showActions = false
    @State private var confirmDelete = false
    @State private var showMove = false
    @State private var showFonts = false
    @State private var showTags = false

    init(path: String) {
        _path = State(initialValue: path)
        _title = State(initialValue: VaultPath.title(ofNoteNamed: VaultPath.name(of: path)))
    }

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(backTitle: folderTitle) {
                HStack(spacing: 0) {
                    InkIconButton(kind: .typeface, label: "notes.font") { showFonts = true }
                    InkIconButton(kind: .more, label: "actions") { showActions = true }
                }
            }
            if let loadError {
                VStack(spacing: 16) {
                    NotebookDoodle(width: 60)
                    HandwrittenText(verbatim: loadError)
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .multilineTextAlignment(.center)
                }
                .padding(30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LiveEditorView(controller: controller) {
                    NoteHeader(
                        title: $title,
                        tags: document.frontMatter.tags,
                        inlineTags: NoteText.inlineTags(in: controller.text),
                        font: controller.font,
                        folder: VaultPath.parent(of: path),
                        onCommitTitle: commitTitle,
                        onEditTags: { showTags = true },
                        onFinishTitle: { controller.host?.hostFocus() }
                    )
                }
                .opacity(isLoaded ? 1 : 0)
            }
        }
        .paperBackground()
        .remnHidesSystemBar()
        .safeAreaInset(edge: .bottom) {
            if isLoaded, showsToolbar {
                NoteToolbar(controller: controller)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: controller.isFocused)
        .task(id: path) { await load() }
        .onChange(of: vault.revision) { _, _ in
            Task { await reloadIfChangedElsewhere() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { Task { await saveNow() } }
        }
        .onDisappear {
            Task { await saveNow() }
        }
        .onAppear {
            appState.currentNotesFolder = VaultPath.parent(of: path)
        }
        .handmadeDialog(
            isPresented: $showActions,
            title: "notes.note",
            message: Text(verbatim: title),
            actions: noteActions
        )
        .handmadeDialog(
            isPresented: $confirmDelete,
            title: "notes.delete.title",
            message: Text("notes.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) { delete() },
                HandmadeDialogAction("cancel", role: .cancel) {}
            ]
        )
        .handmadeDialog(
            isPresented: $showMove,
            title: "notes.move.title",
            message: nil,
            actions: moveActions
        )
        .sheet(isPresented: $showFonts) {
            FontPickerSheet(selection: Binding(get: { controller.font }, set: { setFont($0) }))
        }
        .sheet(isPresented: $showTags) {
            TagEditorSheet(tags: Binding(get: { document.frontMatter.tags }, set: { setTags($0) }))
        }
    }

    private var showsToolbar: Bool {
        RemnPlatform.isMac || controller.isFocused
    }

    private var folderTitle: String {
        let folder = VaultPath.parent(of: path)
        return folder.isEmpty ? String(localized: "section.notes") : VaultPath.name(of: folder)
    }

    // MARK: - Loading and saving

    private func load() async {
        controller.onTextChange = { _ in scheduleSave() }
        do {
            let loaded = try await vault.load(path)
            document = loaded
            savedText = loaded.text
            controller.font = NoteFont(frontMatter: loaded.frontMatter.font)
            controller.setText(loaded.body)
            isLoaded = true
            if loaded.body.isEmpty, title == String(localized: "notes.note.untitled") {
                // A new note: start in the title.
                NoteHeader.focusTitleRequest = path
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            await saveNow()
        }
    }

    private func saveNow() async {
        guard isLoaded else { return }
        var updated = document
        updated.body = controller.text
        let text = updated.text
        guard text != savedText else { return }
        do {
            try await vault.save(updated, to: path)
            document = updated
            savedText = text
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    /// Picks up an edit made on another device or in another app, unless there's unsaved writing here.
    private func reloadIfChangedElsewhere() async {
        guard isLoaded, controller.text == document.body, saveTask == nil || saveTask?.isCancelled == true else { return }
        guard let fresh = try? await vault.load(path) else { return }
        guard fresh.text != savedText else { return }
        document = fresh
        savedText = fresh.text
        controller.font = NoteFont(frontMatter: fresh.frontMatter.font)
        controller.setText(fresh.body)
    }

    // MARK: - Title, tags and font

    private func commitTitle() {
        let clean = VaultPath.sanitized(title)
        guard !clean.isEmpty else {
            title = VaultPath.title(ofNoteNamed: VaultPath.name(of: path))
            return
        }
        guard clean != VaultPath.title(ofNoteNamed: VaultPath.name(of: path)) else { return }
        Task {
            await saveNow()
            do {
                path = try await vault.renameNote(path, to: clean)
                title = VaultPath.title(ofNoteNamed: VaultPath.name(of: path))
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func setTags(_ tags: [String]) {
        document.frontMatter.tags = FrontMatter.cleaned(tags)
        Task { await saveNow() }
    }

    private func setFont(_ font: NoteFont) {
        controller.font = font
        document.frontMatter.font = font == .default ? nil : font.rawValue
        Task { await saveNow() }
    }

    // MARK: - Actions

    private var noteActions: [HandmadeDialogAction] {
        var actions = [
            HandmadeDialogAction("notes.tags", role: .plain) { showTags = true },
            HandmadeDialogAction("notes.font", role: .plain) { showFonts = true },
            HandmadeDialogAction("notes.move", role: .plain) { showMove = true },
        ]
        #if os(macOS)
        actions.append(HandmadeDialogAction("notes.revealInFinder", role: .plain) {
            if let url = vault.url(for: path) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        })
        #endif
        actions += [
            HandmadeDialogAction("delete", role: .destructive) { confirmDelete = true },
            HandmadeDialogAction("cancel", role: .cancel) {},
        ]
        return actions
    }

    private var moveActions: [HandmadeDialogAction] {
        let current = VaultPath.parent(of: path)
        let folders = [(path: "", name: String(localized: "section.notes"), depth: 0)]
            + vault.root.flattened().map { (path: $0.folder.path, name: $0.folder.name, depth: $0.depth + 1) }
        return folders.map { folder in
            let indent = String(repeating: "   ", count: folder.depth)
            return HandmadeDialogAction(verbatim: indent + folder.name, role: folder.path == current ? .normal : .plain) {
                move(to: folder.path)
            }
        } + [HandmadeDialogAction("cancel", role: .cancel) {}]
    }

    private func move(to folder: String) {
        Task {
            await saveNow()
            do {
                path = try await vault.moveNote(path, toFolder: folder)
            } catch {
                appState.errorMessage = error.localizedDescription
            }
        }
    }

    private func delete() {
        saveTask?.cancel()
        isLoaded = false
        Task {
            do {
                try await vault.deleteNote(path)
                dismiss()
                if let index = appState.notesPath.lastIndex(of: .note(path)) {
                    appState.notesPath.remove(at: index)
                }
            } catch {
                isLoaded = true
                appState.errorMessage = error.localizedDescription
            }
        }
    }
}

/// The top of a note: its title, written large, and its tags.
struct NoteHeader: View {
    /// Set by a note that was just made, so its title is ready to be typed.
    @MainActor static var focusTitleRequest: String?

    @Binding var title: String
    let tags: [String]
    let inlineTags: [String]
    let font: NoteFont
    let folder: String
    let onCommitTitle: () -> Void
    let onEditTags: () -> Void
    let onFinishTitle: () -> Void

    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                TextField("notes.title.placeholder", text: $title, axis: .vertical)
                    .font(titleFont)
                    .foregroundStyle(Color.remnInk)
                    .tint(.remnAccent)
                    .textFieldStyle(.plain)
                    .focused($titleFocused)
                    .onChange(of: title) { _, value in
                        // Return ends the title rather than starting a new line.
                        guard value.contains("\n") else { return }
                        title = value.replacingOccurrences(of: "\n", with: "")
                        titleFocused = false
                        onFinishTitle()
                    }
                    .onChange(of: titleFocused) { _, focused in
                        if !focused { onCommitTitle() }
                    }
                    .onSubmit {
                        titleFocused = false
                        onFinishTitle()
                    }
                TitleSwash(seed: title.inkSeed)
            }

            let shownTags = FrontMatter.cleaned(tags + inlineTags)
            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(shownTags, id: \.self) { tag in
                    Button(action: onEditTags) { TagChip(tag: tag) }
                        .buttonStyle(InkPressStyle())
                }
                Button(action: onEditTags) {
                    HStack(spacing: 4) {
                        InkIcon(kind: .plus, color: .remnGraphite, size: 13)
                        HandwrittenText(shownTags.isEmpty ? "notes.tags.add" : "notes.tags.edit")
                            .font(RemnTypography.note)
                            .foregroundStyle(Color.remnGraphite)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(InkPressStyle())
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if NoteHeader.focusTitleRequest != nil {
                NoteHeader.focusTitleRequest = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { titleFocused = true }
            }
        }
    }

    private var titleFont: Font {
        switch font {
        case .neucha: RemnTypography.display(RemnPlatform.isMac ? 34 : 36, relativeTo: .largeTitle)
        default: font.font(size: RemnPlatform.isMac ? 28 : 30, relativeTo: .largeTitle).weight(.semibold)
        }
    }
}
