import AppKit
import ApplicationServices

/// Watches the clipboard and auto-fills 6-digit codes that arrive from the phone
/// via Universal Clipboard (identified by the `com.apple.is-remote-clipboard`
/// pasteboard type). Fills by synthesizing Cmd+V into the frontmost text field.
///
/// Design (see conversation): the Handoff marker is free to read (it rides in the
/// advertised pasteboard *types*, no content pull). Only when a change is both
/// remote-origin and we decide to act do we read the string once and fill.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let remoteType = "com.apple.is-remote-clipboard"

    /// Frontmost-app gate: only fill when one of these browsers is frontmost.
    private let browserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.apple.SafariTechnologyPreview",
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.google.Chrome.beta",
        "com.microsoft.edgemac",
        "com.brave.Browser",
        "company.thebrowser.Browser",   // Arc
        "org.mozilla.firefox",
        "com.vivaldi.Vivaldi",
        "com.operasoftware.Opera",
    ]

    private var window: NSWindow!
    private var textView: NSTextView!
    private var autoFillCheckbox: NSButton!
    private var handoffOnlyCheckbox: NSButton!
    private var browserOnlyCheckbox: NSButton!
    private var focusGuardCheckbox: NSButton!
    private var axStatusLabel: NSTextField!

    private var timer: Timer?
    private var lastChangeCount: Int = -1
    private var eventNumber = 0

    private var autoFillEnabled: Bool { autoFillCheckbox?.state == .on }
    private var handoffOnly: Bool { handoffOnlyCheckbox?.state == .on }
    private var browserOnly: Bool { browserOnlyCheckbox?.state == .on }
    private var focusGuard: Bool { focusGuardCheckbox?.state == .on }

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        promptAccessibility()
        refreshAXStatus()
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.poll()
        }
        NSApp.activate(ignoringOtherApps: true)
        append("Ready. Copy a 6-digit code on your iPhone — it should auto-fill the focused field here.\n\n")
    }

    // MARK: UI

    private func buildWindow() {
        let rect = NSRect(x: 0, y: 0, width: 820, height: 560)
        window = NSWindow(contentRect: rect,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "ClipFill — Handoff Code Auto-Fill"
        window.center()

        let container = NSView(frame: rect)

        let clearButton = NSButton(title: "Clear", target: self, action: #selector(clearLog))
        clearButton.bezelStyle = .rounded

        autoFillCheckbox = NSButton(checkboxWithTitle: "Auto-fill", target: nil, action: nil)
        autoFillCheckbox.state = .on

        handoffOnlyCheckbox = NSButton(checkboxWithTitle: "iPhone only", target: nil, action: nil)
        handoffOnlyCheckbox.state = .on

        browserOnlyCheckbox = NSButton(checkboxWithTitle: "Browser only (Safari/Chrome)", target: nil, action: nil)
        browserOnlyCheckbox.state = .on

        focusGuardCheckbox = NSButton(checkboxWithTitle: "Field focus", target: nil, action: nil)
        focusGuardCheckbox.state = .on

        let axButton = NSButton(title: "Accessibility…", target: self, action: #selector(openAXSettings))
        axButton.bezelStyle = .rounded

        let toolbar = NSStackView(views: [clearButton, autoFillCheckbox, handoffOnlyCheckbox, browserOnlyCheckbox, focusGuardCheckbox, axButton])
        toolbar.orientation = .horizontal
        toolbar.spacing = 10
        toolbar.alignment = .centerY
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(toolbar)

        axStatusLabel = NSTextField(labelWithString: "")
        axStatusLabel.font = .systemFont(ofSize: 11)
        axStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(axStatusLabel)

        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder

        textView = NSTextView()
        textView.isEditable = false
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.autoresizingMask = [.width]
        scroll.documentView = textView
        container.addSubview(scroll)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            toolbar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            toolbar.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12),

            axStatusLabel.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 6),
            axStatusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),

            scroll.topAnchor.constraint(equalTo: axStatusLabel.bottomAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])

        window.contentView = container
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func clearLog() { textView.string = ""; eventNumber = 0 }

    @objc private func openAXSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func append(_ text: String) {
        textView.textStorage?.append(NSAttributedString(
            string: text,
            attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                         .foregroundColor: NSColor.labelColor]))
        textView.scrollToEndOfDocument(nil)
    }

    // MARK: Accessibility

    @discardableResult
    private func promptAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    private func refreshAXStatus() {
        let trusted = AXIsProcessTrusted()
        axStatusLabel.stringValue = trusted
            ? "✅ Accessibility granted — can auto-fill."
            : "🔒 Accessibility NOT granted — grant it (button above) or codes won't type. Re-launch after granting."
        axStatusLabel.textColor = trusted ? .systemGreen : .systemRed
    }

    // MARK: Polling

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        eventNumber += 1

        let types = pb.types ?? []
        let isRemote = types.contains { $0.rawValue == remoteType }   // free — no content pull
        let frontBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let inBrowser = browserBundleIDs.contains(frontBundleID)      // free — no content pull

        // All gate checks below are free (no content read). We only read the
        // clipboard string once every gate passes.
        guard autoFillEnabled else {
            append(logLine(event: eventNumber, isRemote: isRemote, code: nil, action: "skip (auto-fill off)"))
            return
        }
        guard !handoffOnly || isRemote else {
            append(logLine(event: eventNumber, isRemote: isRemote, code: nil, action: "skip (not from iPhone)"))
            return
        }
        guard !browserOnly || inBrowser else {
            append(logLine(event: eventNumber, isRemote: isRemote, code: nil, action: "skip (not a browser)"))
            return
        }

        // One intentional read (this is what a paste would do anyway).
        guard let raw = pb.string(forType: .string), let code = extractCode(from: raw) else {
            append(logLine(event: eventNumber, isRemote: isRemote, code: nil, action: "skip (not a 6-digit code)"))
            return
        }

        if focusGuard && !focusedElementLooksEditable() {
            append(logLine(event: eventNumber, isRemote: isRemote, code: code, action: "skip (focus not a text field)"))
            return
        }

        guard AXIsProcessTrusted() else {
            append(logLine(event: eventNumber, isRemote: isRemote, code: code, action: "BLOCKED (no Accessibility)"))
            promptAccessibility(); refreshAXStatus()
            return
        }

        pasteIntoFrontmostField()
        append(logLine(event: eventNumber, isRemote: isRemote, code: code, action: "FILLED ✅ (Cmd+V)"))
    }

    private func logLine(event: Int, isRemote: Bool, code: String?, action: String) -> String {
        let front = NSWorkspace.shared.frontmostApplication
        let frontDesc = "\(front?.localizedName ?? "?")"
        let origin = isRemote ? "iPhone(Handoff)" : "local"
        return "#\(event) \(timeString())  origin=\(origin)  code=\(code ?? "—")  front=\(frontDesc)  → \(action)\n"
    }

    private func timeString() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }

    // MARK: Code parsing

    private func extractCode(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 8 else { return nil }
        let digits = trimmed.filter(\.isNumber)
        let nonDigits = trimmed.filter { !$0.isNumber }
        guard digits.count >= 6, digits.count <= 8,          // 6–8 digit codes
              nonDigits.allSatisfy({ $0 == " " || $0 == "-" }), nonDigits.count <= 1 else { return nil }
        return digits
    }

    // MARK: Focus inspection

    private func focusedElementLooksEditable() -> Bool {
        let system = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focusedObj = focused else {
            return true   // unknown (common for Chrome web fields) → allow
        }
        let element = focusedObj as! AXUIElement
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

    // MARK: Fill

    private func pasteIntoFrontmostField() {
        // The code is already on the clipboard, so Cmd+V pastes it into the frontmost field.
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

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
