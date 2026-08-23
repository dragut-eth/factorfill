import AppKit

/// The entire UI: a menu-bar icon with a small dropdown.
final class MenuBarController: NSObject {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    override init() {
        super.init()
        showIdleIcon()
        rebuildMenu()
    }

    /// The cube mark, dimmed when disabled.
    private func showIdleIcon() {
        statusItem.button?.image = IconRenderer.menuBarIcon(dimmed: !Prefs.enabled)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let enabled = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabled.target = self
        enabled.state = Prefs.enabled ? .on : .off
        menu.addItem(enabled)

        menu.addItem(.separator())

        // Allowed-apps submenu (checkmarked entries; click to remove).
        let allowed = NSMenuItem(title: "Fill in these apps", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for id in Prefs.allowedBundleIDs {
            let item = NSMenuItem(title: appName(for: id) ?? id, action: #selector(removeApp(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = id
            item.state = .on
            item.toolTip = id
            sub.addItem(item)
        }
        if Prefs.allowedBundleIDs.isEmpty {
            let none = NSMenuItem(title: "(none — nothing will fill)", action: nil, keyEquivalent: "")
            none.isEnabled = false
            sub.addItem(none)
        }
        sub.addItem(.separator())
        let add = NSMenuItem(title: "Add frontmost app", action: #selector(addFrontmost), keyEquivalent: "")
        add.target = self
        sub.addItem(add)
        allowed.submenu = sub
        menu.addItem(allowed)

        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)

        let axTitle = Filler.accessibilityTrusted ? "Accessibility: granted ✓" : "Grant Accessibility…"
        let ax = NSMenuItem(title: axTitle, action: #selector(grantAX), keyEquivalent: "")
        ax.target = self
        menu.addItem(ax)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit FactorFill", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func appName(for bundleID: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }

    // MARK: Actions

    @objc private func toggleEnabled() {
        Prefs.enabled.toggle()
        showIdleIcon()
        rebuildMenu()
    }

    @objc private func toggleLogin() {
        LoginItem.set(!LoginItem.isEnabled)
        rebuildMenu()
    }

    @objc private func grantAX() {
        if !Filler.accessibilityTrusted {
            Filler.promptAccessibility()
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        rebuildMenu()
    }

    /// Adds whatever app is frontmost. For an accessory app, clicking the status
    /// item doesn't change the active app, so this captures the user's real app.
    @objc private func addFrontmost() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let id = app.bundleIdentifier,
              id != Bundle.main.bundleIdentifier else { return }
        if !Prefs.allowedBundleIDs.contains(id) {
            Prefs.allowedBundleIDs.append(id)
        }
        rebuildMenu()
    }

    @objc private func removeApp(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        Prefs.allowedBundleIDs.removeAll { $0 == id }
        rebuildMenu()
    }

    // MARK: Feedback

    /// Briefly flips the menu-bar icon to a checkmark after a successful fill.
    func flash() {
        statusItem.button?.image = NSImage(systemSymbolName: "checkmark.circle.fill",
                                           accessibilityDescription: "Filled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.showIdleIcon()
        }
    }
}
