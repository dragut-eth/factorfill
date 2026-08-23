# FactorFill

A low-profile macOS menu-bar app that **auto-fills 2FA codes sent from your iPhone**.

Copy a one-time code in your phone's authenticator → [Universal Clipboard (Handoff)](https://support.apple.com/en-us/102430) syncs it to your Mac → FactorFill types it into the focused field of an allowed app (Safari/Chrome by default). Works in **any** app — including Chrome — because it types into whatever field has focus, rather than relying on Apple's AutoFill (which is Safari/native-only).

## How it works

FactorFill polls the clipboard and fills only when **all** of these are true, checked cheapest-first so it reads clipboard *content* only when necessary:

1. The item arrived from another device via Universal Clipboard — detected by the `com.apple.is-remote-clipboard` pasteboard type (readable without pulling the content).
2. The frontmost app is on your allow-list.
3. The content is a 6–8 digit code.
4. The focused element is editable.

Then it synthesizes ⌘V into the focused field.

> **Privacy:** FactorFill never reads the *content* of local copies — it only reads content for items that came from your phone. The origin check and app check are pure metadata.

## Requirements

- macOS 13+
- Handoff / Universal Clipboard set up between your iPhone and Mac (same Apple ID, Bluetooth + Wi-Fi on, Handoff enabled)
- **Accessibility permission** (required to type into other apps)

## Build

```bash
./build.sh
open FactorFill.app
```

On first launch, grant Accessibility when prompted (**System Settings → Privacy & Security → Accessibility → enable FactorFill**), then relaunch.

## Usage

Everything lives in the menu-bar icon (🔑):

- **Enabled** — master on/off
- **Fill in these apps** — the allow-list; "Add frontmost app" adds whatever app you're currently in
- **Launch at login**
- **Grant Accessibility…** — shows status / opens settings

## Limitations

- Detects that a code came *from another device* — **not which app** produced it (Apple exposes no originating-app info across Universal Clipboard).
- The `com.apple.is-remote-clipboard` marker is **undocumented** and could change in a future macOS.
- Not distributable via the App Store (Accessibility + synthetic input). Shareable as a signed/notarized build.

## Project layout

```
Sources/FactorFill/   Swift sources
Resources/Info.plist  bundle metadata (LSUIElement menu-bar app)
build.sh              compile + sign into FactorFill.app
poc/                  original proof-of-concept experiments (reference)
```

## License

MIT
