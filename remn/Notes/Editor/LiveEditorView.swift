import SwiftUI

/// The live editor on the page: one field where the note is written and read. `header` scrolls with
/// the text above it — the note's title and tags.
struct LiveEditorView<Header: View>: View {
    let controller: LiveEditorController
    @ViewBuilder var header: Header

    var body: some View {
        PlatformLiveEditor(controller: controller, header: AnyView(header))
    }
}

/// The widest a line of a note gets, however wide the window.
private let readableTextWidth: CGFloat = 700

#if os(iOS)
import UIKit

private struct PlatformLiveEditor: UIViewRepresentable {
    let controller: LiveEditorController
    let header: AnyView

    func makeCoordinator() -> Coordinator { Coordinator(controller: controller) }

    func makeUIView(context: Context) -> LiveTextView {
        let view = LiveTextView(controller: controller)
        view.delegate = context.coordinator
        controller.host = view
        view.setHeader(header.environment(\.self, context.environment))
        return view
    }

    func updateUIView(_ view: LiveTextView, context: Context) {
        view.setHeader(header.environment(\.self, context.environment))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let controller: LiveEditorController

        init(controller: LiveEditorController) {
            self.controller = controller
        }

        func textViewDidChange(_ textView: UITextView) {
            controller.textDidChange()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard (textView as? LiveTextView)?.isRefreshingCaret != true else { return }
            controller.selectionDidChange()
            textView.typingAttributes = controller.typingAttributes
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            controller.focusDidChange(true)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            controller.focusDidChange(false)
        }

        func textView(
            _ textView: UITextView,
            editMenuForTextIn range: NSRange,
            suggestedActions: [UIMenuElement]
        ) -> UIMenu? {
            guard range.length > 0 else { return UIMenu(children: suggestedActions) }
            let makeCard = UIAction(
                title: String(localized: "notes.makeCard"),
                image: UIImage(systemName: "rectangle.stack.badge.plus")
            ) { [controller] _ in
                controller.makeCardFromSelection()
            }
            return UIMenu(children: [UIMenu(options: .displayInline, children: [makeCard])] + suggestedActions)
        }
    }
}

final class LiveTextView: UITextView, LiveTextHost, UIGestureRecognizerDelegate {
    private let controller: LiveEditorController
    fileprivate(set) var isRefreshingCaret = false
    private var headerHost: UIHostingController<AnyView>?
    private var headerHeight: CGFloat = 0

    init(controller: LiveEditorController) {
        self.controller = controller
        super.init(frame: .zero, textContainer: controller.container)
        backgroundColor = .clear
        alwaysBounceVertical = true
        keyboardDismissMode = .interactive
        smartQuotesType = .no
        smartDashesType = .no
        smartInsertDeleteType = .no
        autocapitalizationType = .sentences
        tintColor = LiveTheme.accent
        typingAttributes = controller.typingAttributes
        contentInsetAdjustmentBehavior = .automatic

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        addGestureRecognizer(tap)

        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitDisplayScale.self]) { (view: LiveTextView, _) in
            view.appearanceChanged()
        }
        appearanceChanged()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setHeader(_ view: some View) {
        if let headerHost {
            headerHost.rootView = AnyView(view)
        } else {
            let host = UIHostingController(rootView: AnyView(view))
            host.view.backgroundColor = .clear
            host.safeAreaRegions = []
            host.sizingOptions = [.intrinsicContentSize]
            addSubview(host.view)
            headerHost = host
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side = max(20, (bounds.width - readableTextWidth) / 2)
        let width = max(bounds.width - 2 * side, 100)
        if let header = headerHost?.view {
            let size = header.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            header.frame = CGRect(x: side, y: 0, width: width, height: size.height)
            headerHeight = size.height
        }
        let inset = UIEdgeInsets(top: headerHeight + 8, left: side, bottom: 180, right: side)
        if textContainerInset != inset {
            textContainerInset = inset
        }
        controller.pageWidthDidChange(width)
    }

    private func appearanceChanged() {
        controller.appearanceDidChange(isDark: traitCollection.userInterfaceStyle == .dark, scale: traitCollection.displayScale)
        setNeedsDisplay()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        var point = gesture.location(in: self)
        point.x -= textContainerInset.left
        point.y -= textContainerInset.top
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        _ = controller.toggleTask(at: index)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    // MARK: - Pasting pictures

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)), UIPasteboard.general.hasImages {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }

    override func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasImages, !pasteboard.hasStrings, let image = pasteboard.image,
           let data = image.pngData() {
            controller.onPasteImage(data)
            return
        }
        super.paste(sender)
    }

    // MARK: - LiveTextHost

    var hostSelectedRange: NSRange {
        get { selectedRange }
        set { selectedRange = newValue }
    }

    var hostIsFocused: Bool { isFirstResponder }

    /// Edits made by the app go straight into the text, past the keyboard's autocorrection and smart quotes,
    /// which would otherwise turn a template's `"` into `«`.
    func hostReplace(_ range: NSRange, with text: String) {
        guard NSMaxRange(range) <= textStorage.length else { return }
        let original = textStorage.attributedSubstring(from: range).string
        let inserted = NSRange(location: range.location, length: (text as NSString).length)
        undoManager?.registerUndo(withTarget: self) { view in
            view.hostReplace(inserted, with: original)
            view.selectedRange = NSRange(location: range.location + (original as NSString).length, length: 0)
        }
        textStorage.replaceCharacters(in: range, with: NSAttributedString(string: text, attributes: controller.typingAttributes))
        controller.textDidChange()
    }

    func hostFocus() {
        if !isFirstResponder { becomeFirstResponder() }
    }

    func hostScrollToSelection() {
        scrollRangeToVisible(selectedRange)
    }

    func hostRefreshCaret() {
        guard isFirstResponder, selectedRange.length == 0, let range = selectedTextRange else { return }
        layoutManager.ensureLayout(forCharacterRange: NSRange(location: max(0, selectedRange.location - 1), length: 2))
        isRefreshingCaret = true
        selectedTextRange = nil
        selectedTextRange = range
        isRefreshingCaret = false
    }
}

#else
import AppKit
import UniformTypeIdentifiers

private struct PlatformLiveEditor: NSViewRepresentable {
    let controller: LiveEditorController
    let header: AnyView

    func makeCoordinator() -> Coordinator { Coordinator(controller: controller) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = LiveNSTextView(controller: controller)
        textView.delegate = context.coordinator
        controller.host = textView
        textView.setHeader(header.environment(\.self, context.environment))

        let scrollView = LiveScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.documentView = textView
        scrollView.contentView.drawsBackground = false
        textView.autoresizingMask = [.width]
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        (scrollView.documentView as? LiveNSTextView)?.setHeader(header.environment(\.self, context.environment))
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        let controller: LiveEditorController

        init(controller: LiveEditorController) {
            self.controller = controller
        }

        func textDidChange(_ notification: Notification) {
            controller.textDidChange()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            controller.selectionDidChange()
            (notification.object as? NSTextView)?.typingAttributes = controller.typingAttributes
        }
    }
}

/// Keeps the text exactly as wide as the visible page, however the window is resized.
private final class LiveScrollView: NSScrollView {
    override func tile() {
        super.tile()
        guard let documentView, documentView.frame.width != contentView.bounds.width else { return }
        documentView.setFrameSize(NSSize(width: contentView.bounds.width, height: documentView.frame.height))
    }
}

final class LiveNSTextView: NSTextView, LiveTextHost {
    private let controller: LiveEditorController
    private var headerHost: NSHostingView<AnyView>?
    private var headerHeight: CGFloat = 0
    private var sideInset: CGFloat = 32
    private let bottomSpace: CGFloat = 200

    init(controller: LiveEditorController) {
        self.controller = controller
        super.init(frame: NSRect(x: 0, y: 0, width: 600, height: 400), textContainer: controller.container)
        drawsBackground = false
        isRichText = false
        importsGraphics = false
        allowsUndo = true
        isVerticallyResizable = true
        isHorizontallyResizable = false
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        insertionPointColor = LiveTheme.accent
        typingAttributes = controller.typingAttributes
        selectedTextAttributes = [.backgroundColor: LiveTheme.accent.withAlphaComponent(0.2)]
        minSize = NSSize(width: 0, height: 0)
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textContainer?.widthTracksTextView = true
        appearanceChanged()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        fatalError("use init(controller:)")
    }

    func setHeader(_ view: some View) {
        if let headerHost {
            headerHost.rootView = AnyView(view)
        } else {
            let host = NSHostingView(rootView: AnyView(view))
            host.sizingOptions = [.intrinsicContentSize]
            addSubview(host)
            headerHost = host
        }
        needsLayout = true
        layoutHeader()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        layoutHeader()
    }

    private func layoutHeader() {
        let side = max(32, (bounds.width - readableTextWidth) / 2)
        let width = max(bounds.width - 2 * side, 100)
        var height: CGFloat = 0
        if let header = headerHost {
            height = header.fittingSize(forWidth: width)
            header.frame = NSRect(x: side, y: 0, width: width, height: height)
        }
        if height != headerHeight || side != sideInset {
            headerHeight = height
            sideInset = side
            // The container starts below the header; the inset splits the header and the space at the end.
            textContainerInset = NSSize(width: side, height: (headerHeight + 8 + bottomSpace) / 2)
            invalidateTextContainerOrigin()
        }
        controller.pageWidthDidChange(width)
    }

    override var textContainerOrigin: NSPoint {
        NSPoint(x: sideInset, y: headerHeight + 8)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        appearanceChanged()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        appearanceChanged()
    }

    private func appearanceChanged() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        controller.appearanceDidChange(isDark: isDark, scale: window?.backingScaleFactor ?? 2)
        needsDisplay = true
    }

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { controller.focusDidChange(true) }
        return accepted
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned { controller.focusDidChange(false) }
        return resigned
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let containerPoint = NSPoint(x: point.x - textContainerOrigin.x, y: point.y - textContainerOrigin.y)
        if let layoutManager, let textContainer {
            let index = layoutManager.characterIndex(for: containerPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            if controller.toggleTask(at: index) { return }
        }
        super.mouseDown(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event) ?? NSMenu()
        if selectedRange().length > 0 {
            let item = NSMenuItem(title: String(localized: "notes.makeCard"), action: #selector(makeCard(_:)), keyEquivalent: "")
            item.target = self
            item.image = NSImage(systemSymbolName: "rectangle.stack.badge.plus", accessibilityDescription: nil)
            menu.insertItem(item, at: 0)
            menu.insertItem(.separator(), at: 1)
        }
        return menu
    }

    @objc private func makeCard(_ sender: Any?) {
        controller.makeCardFromSelection()
    }

    // MARK: - Pasting and dropping pictures

    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        if pasteboard.string(forType: .string) == nil, let data = Self.imageData(from: pasteboard) {
            controller.onPasteImage(data)
            return
        }
        super.paste(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true, .urlReadingContentsConformToTypes: [UTType.image.identifier]]
        ) as? [URL] ?? []
        guard !urls.isEmpty || Self.imageData(from: pasteboard) != nil else {
            return super.performDragOperation(sender)
        }
        let point = convert(sender.draggingLocation, from: nil)
        setSelectedRange(NSRange(location: characterIndexForInsertion(at: point), length: 0))
        window?.makeFirstResponder(self)
        if urls.isEmpty, let data = Self.imageData(from: pasteboard) {
            controller.onPasteImage(data)
        }
        for url in urls {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) { controller.onPasteImage(data) }
        }
        return true
    }

    private static func imageData(from pasteboard: NSPasteboard) -> Data? {
        for type in [NSPasteboard.PasteboardType.png, .tiff] {
            if let data = pasteboard.data(forType: type) { return data }
        }
        return nil
    }

    // MARK: - LiveTextHost

    var hostSelectedRange: NSRange {
        get { selectedRange() }
        set { setSelectedRange(newValue) }
    }

    var hostIsFocused: Bool { window?.firstResponder === self }

    func hostReplace(_ range: NSRange, with text: String) {
        guard shouldChangeText(in: range, replacementString: text) else { return }
        textStorage?.replaceCharacters(in: range, with: text)
        didChangeText()
    }

    func hostFocus() {
        window?.makeFirstResponder(self)
    }

    func hostScrollToSelection() {
        scrollRangeToVisible(selectedRange())
    }

    func hostRefreshCaret() {
        updateInsertionPointStateAndRestartTimer(true)
    }
}

private extension NSHostingView {
    func fittingSize(forWidth width: CGFloat) -> CGFloat {
        let saved = frame
        frame = NSRect(x: saved.minX, y: saved.minY, width: width, height: saved.height)
        layoutSubtreeIfNeeded()
        let height = fittingSize.height
        frame = saved
        return ceil(height)
    }
}
#endif
