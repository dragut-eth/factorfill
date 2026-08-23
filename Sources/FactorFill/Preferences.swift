import Foundation

/// Minimal persisted settings (UserDefaults). Deliberately few knobs.
enum Prefs {
    private static let d = UserDefaults.standard

    private static let kEnabled = "enabled"
    private static let kAllowed = "allowedBundleIDs"
    private static let kHandoffOnly = "handoffOnly"

    /// Default apps we fill into: Safari + Chrome.
    static let defaultAllowed = ["com.apple.Safari", "com.google.Chrome"]

    static var enabled: Bool {
        get { d.object(forKey: kEnabled) as? Bool ?? true }
        set { d.set(newValue, forKey: kEnabled) }
    }

    /// Only fill codes that arrived from another device via Universal Clipboard.
    static var handoffOnly: Bool {
        get { d.object(forKey: kHandoffOnly) as? Bool ?? true }
        set { d.set(newValue, forKey: kHandoffOnly) }
    }

    static var allowedBundleIDs: [String] {
        get { d.object(forKey: kAllowed) as? [String] ?? defaultAllowed }
        set { d.set(newValue, forKey: kAllowed) }
    }
}
