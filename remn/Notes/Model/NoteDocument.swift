import Foundation

/// One note: its front matter and the Markdown you write.
struct NoteDocument: Equatable, Sendable {
    var frontMatter: FrontMatter
    var body: String

    init(frontMatter: FrontMatter = FrontMatter(), body: String = "") {
        self.frontMatter = frontMatter
        self.body = body
    }

    init(text: String) {
        let text = text.replacingOccurrences(of: "\r\n", with: "\n")
        guard text.hasPrefix("---\n") else {
            self.init(body: text)
            return
        }
        let afterOpening = text.index(text.startIndex, offsetBy: 4)
        var lineStart = afterOpening
        while true {
            let lineEnd = text[lineStart...].firstIndex(of: "\n") ?? text.endIndex
            let line = text[lineStart..<lineEnd]
            if line == "---" || line == "..." {
                let yaml = String(text[afterOpening..<lineStart])
                var bodyStart = lineEnd < text.endIndex ? text.index(after: lineEnd) : lineEnd
                // One blank line after the front matter belongs to it, not to the note.
                if bodyStart < text.endIndex, text[bodyStart] == "\n" {
                    bodyStart = text.index(after: bodyStart)
                }
                self.init(frontMatter: FrontMatter(yaml: yaml), body: String(text[bodyStart...]))
                return
            }
            guard lineEnd < text.endIndex else { break }
            lineStart = text.index(after: lineEnd)
        }
        self.init(body: text)
    }

    var text: String {
        guard !frontMatter.isEmpty else { return body }
        return "---\n\(frontMatter.yaml)\n---\n\n\(body)"
    }

    /// Tags from the front matter and `#tags` written in the text.
    var allTags: [String] {
        FrontMatter.cleaned(frontMatter.tags + NoteText.inlineTags(in: body))
    }
}

enum NoteText {
    /// `#tags` in running text; headings (`# `), code and links don't count.
    static func inlineTags(in body: String) -> [String] {
        var tags: [String] = []
        var inFence = false
        for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                continue
            }
            guard !inFence else { continue }
            let text = String(line)
            let pattern = #/(?:^|[\s(])#([\p{L}\p{N}_\/-]*[\p{L}_][\p{L}\p{N}_\/-]*)/#
            for match in text.matches(of: pattern) {
                tags.append(String(match.output.1))
            }
        }
        return tags
    }

    /// The first line worth showing under a note's title, without Markdown punctuation.
    static func snippet(of body: String, limit: Int = 160) -> String {
        var inFence = false
        for line in body.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                continue
            }
            guard !inFence, !trimmed.isEmpty, trimmed != "$$", !trimmed.hasPrefix("!["), trimmed != "---" else {
                continue
            }
            let clean = trimmed
                .replacingOccurrences(of: #"^(#{1,6}|>|[-*+]|\d+\.)\s+"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"[*_`~=]"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            guard !clean.isEmpty else { continue }
            return clean.count > limit ? String(clean.prefix(limit)) + "…" : clean
        }
        return ""
    }
}
