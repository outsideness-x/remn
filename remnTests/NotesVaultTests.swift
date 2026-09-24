import Foundation
import Testing
@testable import remn

struct FrontMatterTests {
    @Test func keepsUnknownKeysAndReadsTagsAndFont() {
        let text = """
        ---
        aliases: [lens]
        tags: [optics, "light rays"]
        font: newYork
        cssclasses:
          - wide
        ---

        # Lenses
        """
        var document = NoteDocument(text: text)
        #expect(document.frontMatter.tags == ["optics", "light-rays"])
        #expect(document.frontMatter.font == "newYork")
        #expect(document.body == "# Lenses")

        document.frontMatter.tags.append("physics")
        document.frontMatter.font = nil
        #expect(document.text == """
        ---
        aliases: [lens]
        tags: [optics, light-rays, physics]
        cssclasses:
          - wide
        ---

        # Lenses
        """)
    }

    @Test func readsBlockListsOfTags() {
        let document = NoteDocument(text: "---\ntags:\n  - one\n  - \"#two\"\n---\nbody")
        #expect(document.frontMatter.tags == ["one", "two"])
        #expect(document.body == "body")
    }

    @Test func notesWithoutFrontMatterStayUntouched() {
        let text = "---- not front matter\nhello"
        #expect(NoteDocument(text: text).text == text)
        #expect(NoteDocument(text: "plain").text == "plain")
    }

    @Test func addingATagCreatesFrontMatter() {
        var document = NoteDocument(text: "hello")
        document.frontMatter.tags = ["math"]
        #expect(document.text == "---\ntags: [math]\n---\n\nhello")
        #expect(NoteDocument(text: document.text) == document)
    }

    @Test func inlineTagsSkipHeadingsAndCode() {
        let body = """
        # Heading
        study #calculus and #limits/one-sided
        `#notatag`
        ```
        #nope
        ```
        issue #42 is not a tag
        """
        #expect(NoteText.inlineTags(in: body) == ["calculus", "limits/one-sided"])
    }

    @Test func snippetSkipsMarkdownPunctuation() {
        #expect(NoteText.snippet(of: "# Title\n\n**Bold** [link](x) text") == "Title")
        #expect(NoteText.snippet(of: "```\ncode\n```\n\n$$\nx\n$$\n- item *one*") == "x")
    }
}

@MainActor
struct VaultTests {
    private func makeVault() throws -> (Vault, URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("remn-vault-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return (Vault(rootURL: root), root)
    }

    @Test func foldersAndNotesRoundTrip() async throws {
        let (vault, root) = try makeVault()
        defer { try? FileManager.default.removeItem(at: root) }

        let physics = try await vault.createFolder(named: "Physics", in: "")
        let optics = try await vault.createFolder(named: "Optics", in: physics)
        let note = try await vault.createNote(in: optics, title: "Lenses: basics")
        #expect(note == "Physics/Optics/Lenses basics.md")

        var document = try await vault.load(note)
        document.body = "A lens bends light. #optics"
        document.frontMatter.tags = ["physics"]
        try await vault.save(document, to: note)
        await vault.reload()

        let summary = try #require(vault.root.note(at: note))
        #expect(summary.title == "Lenses basics")
        #expect(summary.snippet == "A lens bends light. #optics")
        #expect(summary.tags == ["physics", "optics"])
        #expect(vault.root.folder(at: physics)?.totalNoteCount == 1)
        #expect(vault.tags.map(\.tag) == ["optics", "physics"])

        let renamed = try await vault.renameNote(note, to: "Thin lenses")
        #expect(renamed == "Physics/Optics/Thin lenses.md")
        let moved = try await vault.moveNote(renamed, toFolder: physics)
        #expect(moved == "Physics/Thin lenses.md")
        let second = try await vault.createNote(in: physics, title: "Thin lenses")
        #expect(second == "Physics/Thin lenses 2.md")

        try await vault.deleteNote(second)
        await vault.reload()
        #expect(vault.root.note(at: second) == nil)
        #expect(vault.root.folder(at: physics)?.notes.count == 1)
    }

    @Test func attachmentsLiveBesideTheNoteAndStayOutOfTheTree() async throws {
        let (vault, root) = try makeVault()
        defer { try? FileManager.default.removeItem(at: root) }

        let folder = try await vault.createFolder(named: "Biology", in: "")
        let note = try await vault.createNote(in: folder, title: "Cell")
        let link = try await vault.saveAttachment(Data([0x89, 0x50]), fileExtension: "png", forNoteAt: note)
        #expect(link.hasPrefix("attachments/image "))
        #expect(vault.resolveLink(link, fromNoteAt: note)?.lastPathComponent == VaultPath.name(of: link))
        #expect(vault.resolveLink("../../etc/passwd", fromNoteAt: note) == nil)

        await vault.reload()
        #expect(vault.root.folder(at: folder)?.folders.isEmpty == true)
    }
}
