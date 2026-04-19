import Cocoa
import ApplicationServices

/// Helper for checking and requesting macOS Accessibility permissions.
/// Also provides methods to get selected text using clipboard fallback.
enum AccessibilityHelper {

    /// Returns `true` if the app currently has Accessibility (AXIsProcessTrusted) access.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Returns `true` if trusted; otherwise prompts the system dialog and returns `false`.
    /// The caller should re-check after the user interacts with the dialog.
    @discardableResult
    static func requestTrust() -> Bool {
        // Passing `true` shows the system prompt automatically.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Reads the selected text from the currently focused accessibility element.
    /// Falls back to clipboard method if Accessibility API doesn't work.
    /// Returns `nil` when no text is selected or access is denied.
    static func selectedText() -> String? {
        guard isTrusted else { return nil }

        // Try Accessibility API first (faster, no side effects)
        if let text = selectedTextViaAccessibility(), !text.isEmpty {
            return text
        }

        // Fall back to clipboard method (works with more apps)
        return selectedTextViaClipboard()
    }

    // MARK: - Accessibility API Method

    /// Try to get selected text via Accessibility API.
    private static func selectedTextViaAccessibility() -> String? {
        // Get the system-wide accessibility element.
        let systemWide = AXUIElementCreateSystemWide()

        // Obtain the focused application.
        var focusedApp: CFTypeRef?
        let appResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        guard appResult == .success, let app = focusedApp else { return nil }

        // Obtain the focused UI element within that app.
        var focusedElement: CFTypeRef?
        let elementResult = AXUIElementCopyAttributeValue(
            app as! AXUIElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard elementResult == .success, let element = focusedElement else { return nil }

        // Try to read the selected text attribute.
        var selectedTextValue: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )
        guard textResult == .success else { return nil }

        // The attribute is typically an NSString.
        if let text = selectedTextValue as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }

        // Fallback: try selected text range + value substring.
        return selectedTextViaRange(element: element as! AXUIElement)
    }

    /// Fallback path: read `AXValue` and `AXSelectedTextRange`, then substring.
    private static func selectedTextViaRange(element: AXUIElement) -> String? {
        var valueRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef) == .success,
              let fullText = valueRef as? String else { return nil }

        var rangeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
              let rangeValue = rangeRef else { return nil }

        var cfRange = CFRange(location: 0, length: 0)
        guard AXValueGetValue(rangeValue as! AXValue, .cfRange, &cfRange) else { return nil }

        guard cfRange.location >= 0, cfRange.length > 0,
              cfRange.location + cfRange.length <= fullText.count else { return nil }

        let start = fullText.index(fullText.startIndex, offsetBy: cfRange.location)
        let end = fullText.index(start, offsetBy: cfRange.length)
        let substring = String(fullText[start..<end])
        return substring.isEmpty ? nil : substring
    }

    // MARK: - Clipboard Method (Fallback)

    /// Get selected text by simulating Cmd+C and reading from clipboard.
    /// This works with apps that don't expose text via Accessibility API.
    private static func selectedTextViaClipboard() -> String? {
        let pasteboard = NSPasteboard.general

        // Save current clipboard content
        var originalData: [NSPasteboard.PasteboardType: Data] = [:]
        if let originalTypes = pasteboard.types {
            for type in originalTypes {
                if let data = pasteboard.data(forType: type) {
                    originalData[type] = data
                }
            }
        }

        // Clear clipboard to detect if copy operation succeeds
        pasteboard.clearContents()

        // Simulate Cmd+C to copy selected text
        let source = CGEventSource(stateID: .combinedSessionState)

        // Press Cmd+C
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // 0x08 = 'C'
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        // Small delay to let the copy complete
        Thread.sleep(forTimeInterval: 0.05)

        // Release Cmd+C
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)

        // Wait for clipboard to update
        Thread.sleep(forTimeInterval: 0.1)

        // Read the copied text
        var selectedText: String?
        if let string = pasteboard.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                selectedText = trimmed
            }
        }

        // Restore original clipboard content
        pasteboard.clearContents()
        for (type, data) in originalData {
            pasteboard.setData(data, forType: type)
        }

        return selectedText
    }
}
