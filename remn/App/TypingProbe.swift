#if DEBUG && os(macOS)
import AppKit

/// Checks typing on the Mac without a keyboard: launch with `-typingProbe` (and `-openNote`), and the
/// app types into the open note in bursts, pausing long enough for it to save, then writes where each
/// key went to `~/Library/Containers/com.chemical-pink.remn/Data/tmp/typing-probe.txt`.
@MainActor
enum TypingProbe {
    static func scheduleIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-typingProbe") else { return }
        Task { await run() }
    }

    private static func run() async {
        var log: [String] = []
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("typing-probe.txt")
        func write() { try? log.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8) }

        log.append("probe started")
        write()
        try? await Task.sleep(for: .seconds(3))
        log.append("windows: " + NSApp.windows.map { "\(type(of: $0)) visible \($0.isVisible) main \($0.canBecomeMain)" }.joined(separator: "; "))
        write()
        guard let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }) else {
            log.append("no window")
            write()
            return
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        let arguments = ProcessInfo.processInfo.arguments
        let newNote = arguments.firstIndex(of: "-typingProbe").map { arguments.indices.contains($0 + 1) && arguments[$0 + 1] == "newNote" } ?? false
        if newNote {
            // ⌘N, as a person would: a new note opens with its title ready for typing.
            press("n", in: window, modifiers: .command)
            try? await Task.sleep(for: .seconds(1.5))
            if textView(in: window.contentView) == nil {
                // Or a click on the "new note" button at the foot of the page.
                log.append("⌘N opened nothing; clicking the button")
                click(at: NSPoint(x: window.frame.width * 0.64, y: 46), in: window)
                try? await Task.sleep(for: .seconds(1.5))
            }
        }
        guard let editor = textView(in: window.contentView) else {
            log.append("no editor")
            write()
            return
        }
        if newNote {
            // Where a new note's title is typed, whether or not the app could make it the focus.
            if window.firstResponder === window, let title = textField(in: editor) {
                log.append("focusing the title field by hand")
                window.makeFirstResponder(title)
            }
        } else {
            window.makeFirstResponder(editor)
            editor.setSelectedRange(NSRange(location: (editor.string as NSString).length, length: 0))
        }
        log.append("start: responder \(describe(window.firstResponder)), length \(editor.string.count)")

        for burst in 0..<4 {
            for character in (newNote && burst == 1 ? "\r" : "ab ") {
                press(character, in: window)
                try? await Task.sleep(for: .milliseconds(150))
                let current = textView(in: window.contentView)
                log.append(
                    "burst \(burst) \(String(character).debugDescription): responder \(describe(window.firstResponder)) "
                        + "\((window.firstResponder as? NSText)?.string.suffix(12).debugDescription ?? ""), "
                        + "note \(current?.string.suffix(12).debugDescription ?? "-"), same editor \(current === editor), key \(window.isKeyWindow)"
                )
            }
            // Long enough for the note to save and the folder to be read again.
            try? await Task.sleep(for: .seconds(1.5))
            let current = textView(in: window.contentView)
            log.append("after pause: responder \(describe(window.firstResponder)), same editor \(current === editor), editor \(current.map { String(describing: ObjectIdentifier($0)) } ?? "none")")
            write()
        }
        log.append("end: \((textView(in: window.contentView)?.string ?? "").suffix(40).debugDescription)")
        write()
    }

    private static func press(_ character: Character, in window: NSWindow, modifiers: NSEvent.ModifierFlags = []) {
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            guard let event = NSEvent.keyEvent(
                with: type,
                location: .zero,
                modifierFlags: modifiers,
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber,
                context: nil,
                characters: String(character),
                charactersIgnoringModifiers: String(character),
                isARepeat: false,
                keyCode: ["a": 0, "b": 11, "n": 45, " ": 49, "\r": 36][character] ?? 0
            ) else { continue }
            // Straight to the window: while someone works in another app, this one can't become key.
            if modifiers.isEmpty { window.sendEvent(event) } else { NSApp.sendEvent(event) }
        }
    }

    private static func click(at point: NSPoint, in window: NSWindow) {
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            guard let event = NSEvent.mouseEvent(
                with: type,
                location: point,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: type == .leftMouseDown ? 1 : 0
            ) else { continue }
            NSApp.sendEvent(event)
        }
    }

    private static func textField(in view: NSView) -> NSTextField? {
        for subview in view.subviews {
            if let field = subview as? NSTextField, field.isEditable { return field }
            if let found = textField(in: subview) { return found }
        }
        return nil
    }

    private static func textView(in view: NSView?) -> LiveNSTextView? {
        guard let view else { return nil }
        if let found = view as? LiveNSTextView { return found }
        for subview in view.subviews {
            if !subview.isHidden, let found = textView(in: subview) { return found }
        }
        return nil
    }

    private static func describe(_ responder: NSResponder?) -> String {
        guard let responder else { return "nil" }
        return String(describing: type(of: responder))
    }
}
#endif
