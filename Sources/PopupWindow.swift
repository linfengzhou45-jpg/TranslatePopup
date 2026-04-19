import Cocoa

/// A borderless floating panel that displays translation results near the cursor.
final class PopupWindow: NSPanel {

    // MARK: - UI elements

    private let scrollView = NSScrollView()
    private let textView = NSTextView()
    private let spinner = NSProgressIndicator()
    private let sourceLabel = NSTextField(labelWithString: "")
    private let closeButton = NSButton()

    // MARK: - Callbacks
    
    /// Called when popup is dismissed
    var onDismiss: (() -> Void)?

    // MARK: - Constants

    private static let maxWidth: CGFloat = 400
    private static let maxHeight: CGFloat = 200
    private static let padding: CGFloat = 12
    private static let cornerRadius: CGFloat = 10
    private static let mouseMargin: CGFloat = 16

    // MARK: - Init

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: PopupWindow.maxWidth, height: PopupWindow.maxHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        // Panel behaviour
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        hasShadow = true
        backgroundColor = .clear
        isOpaque = false

        // Content view
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = PopupWindow.cornerRadius
        container.layer?.masksToBounds = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Source label (shows "Translating…" while loading)
        sourceLabel.font = .systemFont(ofSize: 11, weight: .medium)
        sourceLabel.textColor = .secondaryLabelColor
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false

        // Close button
        closeButton.title = "✕"
        closeButton.bezelStyle = .regularSquare
        closeButton.isBordered = false
        closeButton.font = .systemFont(ofSize: 12, weight: .medium)
        closeButton.contentTintColor = .secondaryLabelColor
        closeButton.target = self
        closeButton.action = #selector(dismiss)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        // Spinner
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.isDisplayedWhenStopped = false

        // Text view inside scroll view
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(sourceLabel)
        container.addSubview(closeButton)
        container.addSubview(spinner)
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            sourceLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: PopupWindow.padding),
            sourceLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: PopupWindow.padding),
            sourceLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -4),

            closeButton.topAnchor.constraint(equalTo: container.topAnchor, constant: PopupWindow.padding - 2),
            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -PopupWindow.padding + 2),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20),

            spinner.centerYAnchor.constraint(equalTo: sourceLabel.centerYAnchor),
            spinner.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),

            scrollView.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: PopupWindow.padding),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -PopupWindow.padding),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -PopupWindow.padding),
        ])

        self.contentView = container
    }

    // MARK: - Public API

    /// Show the popup near the mouse cursor with a loading state.
    func showNearCursor() {
        positionNearCursor()
        showLoading()
        orderFrontRegardless()
    }

    /// Update with the translated text.
    func showResult(_ text: String, source: String) {
        spinner.stopAnimation(nil)
        sourceLabel.stringValue = "翻译结果"
        textView.string = text
        resizeToFit()
    }

    /// Update with an error message.
    func showError(_ message: String) {
        spinner.stopAnimation(nil)
        sourceLabel.stringValue = "错误"
        textView.string = message
        textView.textColor = .systemRed
        resizeToFit()
    }

    /// Dismiss the popup.
    @objc func dismiss() {
        orderOut(nil)
        textView.textColor = .labelColor
        onDismiss?()
    }

    // MARK: - Private helpers

    private func showLoading() {
        sourceLabel.stringValue = "翻译中…"
        textView.string = ""
        textView.textColor = .labelColor
        spinner.startAnimation(nil)
        setContentSize(NSSize(width: PopupWindow.maxWidth, height: 60))
    }

    private func positionNearCursor() {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero

        var origin = NSPoint(
            x: mouseLocation.x + PopupWindow.mouseMargin,
            y: mouseLocation.y - frame.height - PopupWindow.mouseMargin
        )

        // Keep within screen bounds.
        if origin.x + frame.width > screenFrame.maxX {
            origin.x = mouseLocation.x - frame.width - PopupWindow.mouseMargin
        }
        if origin.y < screenFrame.minY {
            origin.y = mouseLocation.y + PopupWindow.mouseMargin
        }

        setFrameOrigin(origin)
    }

    private func resizeToFit() {
        let textHeight = textView.textStorage?.size().height ?? 0
        let labelHeight: CGFloat = 18
        let totalHeight = min(
            max(textHeight + labelHeight + PopupWindow.padding * 2 + 6, 60),
            PopupWindow.maxHeight
        )
        var frame = self.frame
        let delta = totalHeight - frame.height
        frame.origin.y -= delta
        frame.size.height = totalHeight
        setFrame(frame, display: true, animate: true)
    }
}
