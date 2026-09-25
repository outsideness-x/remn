import Foundation

/// What the library knows about a note without opening it.
struct NoteSummary: Identifiable, Hashable, Sendable {
    /// Relative to the notes folder, with the extension: `Physics/Optics/Lenses.md`.
    var path: String
    var title: String
    var snippet: String
    var tags: [String]
    var font: String?
    var modified: Date
    /// False while iCloud is still bringing the file down.
    var isDownloaded: Bool

    var id: String { path }
    var folderPath: String { VaultPath.parent(of: path) }
}

/// A folder of notes. Top-level folders are subjects; they can hold folders of their own.
struct VaultFolder: Identifiable, Hashable, Sendable {
    /// Relative to the notes folder; the root is `""`.
    var path: String
    var name: String
    var folders: [VaultFolder]
    var notes: [NoteSummary]

    var id: String { path }
    var isRoot: Bool { path.isEmpty }

    var allNotes: [NoteSummary] {
        notes + folders.flatMap(\.allNotes)
    }

    /// The note a `[[wiki link]]` written in `notePath` points to: by its path when the link names folders,
    /// otherwise by title, the note's own folder first. A `#heading` after the name is ignored.
    func notePath(linkedAs link: String, from notePath: String) -> String? {
        var name = link
        if let heading = name.firstIndex(of: "#") { name = String(name[..<heading]) }
        name = name.trimmingCharacters(in: .whitespaces)
        if name.lowercased().hasSuffix(".md") { name = String(name.dropLast(3)) }
        guard !name.isEmpty else { return nil }
        let notes = allNotes
        if name.contains("/") {
            let wanted = name.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + ".md"
            return notes.first { $0.path.caseInsensitiveCompare(wanted) == .orderedSame }?.path
        }
        let named = notes.filter { $0.title.caseInsensitiveCompare(name) == .orderedSame }
        let folder = VaultPath.parent(of: notePath)
        return (named.first { $0.folderPath == folder } ?? named.first)?.path
    }

    var totalNoteCount: Int {
        notes.count + folders.reduce(0) { $0 + $1.totalNoteCount }
    }

    func folder(at path: String) -> VaultFolder? {
        if path == self.path { return self }
        for folder in folders {
            if path == folder.path || path.hasPrefix(folder.path + "/") {
                return folder.folder(at: path)
            }
        }
        return nil
    }

    func note(at path: String) -> NoteSummary? {
        allNotes.first { $0.path == path }
    }

    /// Every folder below this one, depth first, with how deep it sits.
    func flattened(depth: Int = 0) -> [(folder: VaultFolder, depth: Int)] {
        folders.flatMap { [($0, depth)] + $0.flattened(depth: depth + 1) }
    }
}

enum VaultPath {
    static let noteExtensions: Set<String> = ["md", "markdown"]
    /// Pictures pasted into notes go into a folder with this name next to the note, and it isn't listed.
    static let attachmentsFolder = "attachments"

    static func parent(of path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else { return "" }
        return String(path[..<slash])
    }

    static func name(of path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else { return path }
        return String(path[path.index(after: slash)...])
    }

    static func join(_ folder: String, _ name: String) -> String {
        folder.isEmpty ? name : "\(folder)/\(name)"
    }

    static func title(ofNoteNamed name: String) -> String {
        (name as NSString).deletingPathExtension
    }

    /// A file name that works on every file system iCloud syncs to.
    static func sanitized(_ name: String) -> String {
        let cleaned = name
            .components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>\n\r\t"))
            .joined(separator: " ")
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return String(cleaned.prefix(120))
    }
}

/// Reads the notes folder into a tree. Runs off the main actor.
enum VaultScanner {
    static func scan(root: URL, reusing previous: [String: NoteSummary]) -> VaultFolder {
        scanFolder(at: root, path: "", name: root.lastPathComponent, reusing: previous)
    }

    private static let keys: [URLResourceKey] = [
        .isDirectoryKey, .contentModificationDateKey, .isHiddenKey,
        .ubiquitousItemDownloadingStatusKey, .isUbiquitousItemKey,
    ]

    private static func scanFolder(
        at url: URL,
        path: String,
        name: String,
        reusing previous: [String: NoteSummary]
    ) -> VaultFolder {
        let manager = FileManager.default
        let children = (try? manager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: []
        )) ?? []

        var folders: [VaultFolder] = []
        var notes: [NoteSummary] = []
        for child in children {
            var fileName = child.lastPathComponent
            var isPlaceholder = false
            // iOS keeps files still in iCloud as `.Name.md.icloud` stand-ins.
            if fileName.hasPrefix("."), fileName.hasSuffix(".icloud") {
                fileName = String(fileName.dropFirst().dropLast(".icloud".count))
                isPlaceholder = true
            } else if fileName.hasPrefix(".") {
                continue
            }
            let values = try? child.resourceValues(forKeys: Set(keys))
            let childPath = VaultPath.join(path, fileName)

            if values?.isDirectory == true, !isPlaceholder {
                guard fileName.lowercased() != VaultPath.attachmentsFolder else { continue }
                folders.append(scanFolder(at: child, path: childPath, name: fileName, reusing: previous))
                continue
            }

            let ext = (fileName as NSString).pathExtension.lowercased()
            guard VaultPath.noteExtensions.contains(ext) else { continue }
            let realURL = isPlaceholder ? url.appendingPathComponent(fileName) : child
            let modified = values?.contentModificationDate ?? .distantPast
            let status = values?.ubiquitousItemDownloadingStatus
            let downloaded = !isPlaceholder && (status == nil || status == .current || status == .downloaded)

            if !downloaded {
                try? manager.startDownloadingUbiquitousItem(at: realURL)
            }

            if let cached = previous[childPath], cached.modified == modified, cached.isDownloaded == downloaded {
                notes.append(cached)
                continue
            }

            var summary = NoteSummary(
                path: childPath,
                title: VaultPath.title(ofNoteNamed: fileName),
                snippet: "",
                tags: [],
                font: nil,
                modified: modified,
                isDownloaded: downloaded
            )
            if downloaded, let text = try? VaultFiles.read(realURL) {
                let document = NoteDocument(text: text)
                summary.snippet = NoteText.snippet(of: document.body)
                summary.tags = document.allTags
                summary.font = document.frontMatter.font
            }
            notes.append(summary)
        }

        folders.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        notes.sort { $0.modified > $1.modified }
        return VaultFolder(path: path, name: name, folders: folders, notes: notes)
    }
}

/// Coordinated reads and writes, so iCloud and other apps never see half a file.
enum VaultFiles {
    static func read(_ url: URL) throws -> String {
        var result: Result<String, Error> = .failure(CocoaError(.fileReadUnknown))
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { url in
            result = Result { try String(contentsOf: url, encoding: .utf8) }
        }
        if let coordinationError { throw coordinationError }
        return try result.get()
    }

    static func write(_ text: String, to url: URL) throws {
        try write(Data(text.utf8), to: url)
    }

    static func write(_ data: Data, to url: URL) throws {
        var result: Result<Void, Error> = .success(())
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { url in
            result = Result { try data.write(to: url, options: .atomic) }
        }
        if let coordinationError { throw coordinationError }
        try result.get()
    }

    static func move(_ source: URL, to destination: URL) throws {
        var result: Result<Void, Error> = .success(())
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(
            writingItemAt: source, options: .forMoving,
            writingItemAt: destination, options: .forReplacing,
            error: &coordinationError
        ) { from, to in
            result = Result { try FileManager.default.moveItem(at: from, to: to) }
        }
        if let coordinationError { throw coordinationError }
        try result.get()
    }

    static func delete(_ url: URL) throws {
        var result: Result<Void, Error> = .success(())
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordinationError) { url in
            result = Result {
                do {
                    try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                } catch {
                    try FileManager.default.removeItem(at: url)
                }
            }
        }
        if let coordinationError { throw coordinationError }
        try result.get()
    }

    static func createFolder(_ url: URL) throws {
        var result: Result<Void, Error> = .success(())
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: [], error: &coordinationError) { url in
            result = Result { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) }
        }
        if let coordinationError { throw coordinationError }
        try result.get()
    }

    /// `name.ext`, or `name 2.ext`, `name 3.ext`… if that's taken.
    static func availableURL(named name: String, extension ext: String?, in folder: URL) -> URL {
        let manager = FileManager.default
        func candidate(_ index: Int) -> URL {
            let base = index == 1 ? name : "\(name) \(index)"
            let file = ext.map { "\(base).\($0)" } ?? base
            return folder.appendingPathComponent(file, isDirectory: ext == nil)
        }
        var index = 1
        while index < 10_000 {
            let url = candidate(index)
            let placeholder = folder.appendingPathComponent(".\(url.lastPathComponent).icloud")
            if !manager.fileExists(atPath: url.path), !manager.fileExists(atPath: placeholder.path) {
                return url
            }
            index += 1
        }
        return candidate(Int.random(in: 10_000...99_999))
    }
}
