import Cocoa
import ApplicationServices

/// Helper for checking and requesting macOS Accessibility permissions.
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
    /// Returns `nil` when no text is selected or access is denied.
    static func selectedText() -> String? {
        guard isTrusted else { return nil }

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
}
