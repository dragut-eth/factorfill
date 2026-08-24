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

- macOS 13 (Ventura) or later
- Xcode command-line tools (for `swiftc`). If you don't have them: `xcode-select --install`
- Handoff / Universal Clipboard set up between your iPhone and Mac (same Apple ID, Bluetooth + Wi-Fi on, Handoff enabled)
- **Accessibility permission** (required to type into other apps)

## Build

```bash
git clone https://github.com/dragut-eth/factorfill.git
cd factorfill
bash build.sh
open FactorFill.app
```

### First run

1. The cube appears in your menu bar. It shows as an **outline cube + "!"** until you grant permission.
2. Click the menu-bar icon → **Grant Accessibility…** → in System Settings, enable **FactorFill** under Privacy & Security → Accessibility.
3. **Quit and relaunch** (`open FactorFill.app`) so it picks up the permission. The icon turns solid when it's ready.

### Use it

- Make sure Handoff/Universal Clipboard works between your Mac and iPhone (see Requirements).
- In the menu, **Fill in these apps** lists where filling is allowed (Safari + Chrome by default; "Add frontmost app" to add others).
- Click into a login/2FA field in an allowed app, copy a code on your iPhone → it types into the field automatically.

### Note on code signing

`build.sh` tries to sign with the original author's development certificate. If that cert isn't in your keychain, it **automatically falls back to ad-hoc signing** — the app still builds and runs, but macOS treats each rebuild as a new app, so you'll need to re-grant Accessibility after every rebuild.

To sign stably with your own identity (so the grant persists across rebuilds), list your identities with `security find-identity -v -p codesigning` and set the `IDENTITY=` line in `build.sh` to your `"Apple Development: …"` identity.

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
