import AppKit

/// FactorFill — a low-profile menu-bar app that auto-fills 2FA codes arriving
/// from your iPhone via Universal Clipboard (Handoff), typing them into the
/// focused field of an allowed app (Safari/Chrome by default).
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let menu = MenuBarController()
    private let watcher = ClipboardWatcher()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Filler.promptAccessibility()          // ask once on first launch
        watcher.onFill = { [weak self] _ in
            self?.menu.flash()
        }
        watcher.start()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)           // menu-bar only, no Dock icon, never steals focus
let delegate = AppDelegate()
app.delegate = delegate
app.run()
