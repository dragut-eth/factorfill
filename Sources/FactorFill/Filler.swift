import AppKit
import ApplicationServices

/// Accessibility checks + the actual paste (synthesized Cmd+V).
enum Filler {

    static var accessibilityTrusted: Bool { AXIsProcessTrusted() }

    @discardableResult
    static func promptAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// True if the frontmost app's focused element looks editable. Returns true
    /// when the role can't be determined (common for Chrome web fields) so we
    /// don't wrongly block those.
    static func focusedElementIsEditable() -> Bool {
        let system = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let obj = focused else { return true }
        let element = obj as! AXUIElement

        var roleValue: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success,
           let role = roleValue as? String {
            let editable: Set<String> = ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField", "AXSecureTextField"]
            if editable.contains(role) { return true }
            var settable: DarwinBoolean = false
            if AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &settable) == .success,
               settable.boolValue { return true }
            return false
        }
        return true
    }

    /// Pastes the current clipboard (the code) into the frontmost field via Cmd+V.
    static func paste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09   // kVK_ANSI_V
        let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
