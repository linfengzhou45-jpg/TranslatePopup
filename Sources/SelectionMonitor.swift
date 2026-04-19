import Cocoa
import CoreGraphics

/// Monitors global mouse events and translates selected text when the user
/// finishes a text selection (mouse-up).
final class SelectionMonitor {

    // MARK: - Properties

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRunning = false

    private let translationService = TranslationService()
    private let popup = PopupWindow()

    /// Debounce: ignore rapid-fire mouse-ups (e.g. double-click).
    private var lastTriggerTime: TimeInterval = 0
    private static let debounceInterval: TimeInterval = 0.4

    /// Prevent re-entrancy while a translation is in-flight.
    private var isTranslating = false

    /// Track if popup is currently visible
    private var isPopupVisible = false

    // MARK: - Lifecycle

    /// Starts monitoring. Returns `false` if the event tap could not be created
    /// (e.g. Accessibility permission missing).
    @discardableResult
    func start() -> Bool {
        // Set up popup dismiss callback
        popup.onDismiss = { [weak self] in
            self?.isPopupVisible = false
            self?.isTranslating = false
        }
        
        guard !isRunning else { return true }

        // We need an event tap for mouse-up events.
        let mask: CGEventMask = (1 << CGEventType.leftMouseUp.rawValue)

        // `self` pointer passed to the C callback.
        let pointer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: mouseEventCallback,
            userInfo: pointer
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        return true
    }

    func stop() {
        guard isRunning else { return }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        popup.dismiss()
    }

    // MARK: - Event handling (called on the tap's run-loop)

    fileprivate func handleMouseUp() {
        let now = Date.timeIntervalSinceReferenceDate
        
        // If popup is visible, dismiss it on next click
        if isPopupVisible {
            popup.dismiss()
            lastTriggerTime = now
            return
        }
        
        guard now - lastTriggerTime > SelectionMonitor.debounceInterval else { return }
        lastTriggerTime = now

        guard !isTranslating else { return }

        // Small delay lets the target app update its AX selection after mouse-up.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.translateSelection()
        }
    }

    private func translateSelection() {
        // Add a flag to prevent clipboard method from triggering another translation
        guard !isTranslating else { return }
        
        // Try to get selected text (with clipboard fallback)
        guard let text = AccessibilityHelper.selectedText(),
              text.count <= 5000 else {
            return
        }

        isTranslating = true
        isPopupVisible = true
        popup.showNearCursor()

        translationService.translate(text) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let translated):
                self.popup.showResult(translated, source: text)
            case .failure(let error):
                self.popup.showError(error.localizedDescription)
            }
            self.isTranslating = false
        }
    }
}

// MARK: - C callback bridge

/// Global C-compatible callback invoked by the CGEvent tap.
private func mouseEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }
    let monitor = Unmanaged<SelectionMonitor>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .leftMouseUp {
        monitor.handleMouseUp()
    }

    return Unmanaged.passUnretained(event)
}
