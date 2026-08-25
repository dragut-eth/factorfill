import AppKit

/// Polls the clipboard and, when a fresh item passes all (free) gates, reads it
/// once and auto-fills if it's a 6–8 digit code.
///
/// Gate order is cheapest-first so we only read clipboard *content* when needed:
///   1. changeCount bumped        (free)
///   2. Handoff origin marker      (free — advertised type, no content pull)
///   3. frontmost app is allowed   (free)
///   4. read string once → 6–8 digits?
///   5. focused element editable?
///   6. Accessibility granted → paste
final class ClipboardWatcher {

    /// Undocumented pasteboard type Universal Clipboard stamps on remote items.
    static let remoteType = "com.apple.is-remote-clipboard"

    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    /// Called (on the main thread) with the code after a successful fill.
    var onFill: ((String) -> Void)?

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount   // consume even when disabled, so re-enabling won't fill a stale code

        guard Prefs.enabled else { return }

        let types = pb.types ?? []
        let isRemote = types.contains { $0.rawValue == Self.remoteType }
        if Prefs.handoffOnly && !isRemote { return }

        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        guard Prefs.allowedBundleIDs.contains(front) else { return }

        guard let raw = pb.string(forType: .string), let code = Self.extractCode(raw) else { return }
        guard Filler.focusedElementIsEditable() else { return }
        guard Filler.accessibilityTrusted else { Filler.promptAccessibility(); return }

        Filler.paste()
        onFill?(code)
    }

    /// Accepts a string that is exactly 6–8 digits, optionally split by a single
    /// space or hyphen (e.g. "123456", "123 456", "12 345 6" is rejected — one sep max).
    static func extractCode(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 9 else { return nil }
        let digits = trimmed.filter(\.isNumber)
        let nonDigits = trimmed.filter { !$0.isNumber }
        guard (6...8).contains(digits.count),
              nonDigits.allSatisfy({ $0 == " " || $0 == "-" }),
              nonDigits.count <= 1 else { return nil }
        return digits
    }
}
