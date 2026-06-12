# Safari Tab Tab

A lightweight Safari extension for **MRU tab switching** with `Control+Tab` (Firefox / Alt+Tab style behavior).

- macOS 13+
- Native Swift, no network calls, no analytics
- Menu bar agent (no Dock icon)
- Open source (MIT)

## Behavior

| Action | Result |
|--------|--------|
| Quick `Ctrl+Tab` | Switch to the previous (MRU) tab |
| Hold `Ctrl+Tab` ~0.2s | Show a picker of recent tabs |
| `Ctrl+Tab` while picker is open | Move forward in history |
| `Ctrl+Shift+Tab` | Move backward in history |
| Release `Ctrl` | Switch to the selected tab |

## Clone

```bash
git clone https://github.com/1kub/safari-tab-tab.git ~/Documents/safari-tab-tab
cd ~/Documents/safari-tab-tab
```

## First-time setup (free Apple ID)

1. Open `SafariTabTab.xcodeproj` in Xcode.
2. In both targets (`Safari Tab Tab`, `Safari Tab Tab Extension`), set **Signing & Capabilities** to your Apple ID (Personal Team).
3. Enable **App Groups** with ID `group.com.1kub.safaritabtab` in both targets.
4. Build and install:

```bash
chmod +x Scripts/reinstall.sh
./Scripts/reinstall.sh
```

5. Safari → **Settings → Extensions** → enable **Safari Tab Tab Extension** → “Always Allow on Every Website”.
6. Keep the **Safari Tab Tab** icon in the Safari toolbar (required for reliable operation).

## Re-sign after 7 days (free provisioning)

Without a paid Developer account, the signature expires after about **7 days**.

**From the Safari Tab Tab menu bar icon:** “Re-sign App” (or in Terminal):

```bash
./Scripts/reinstall.sh
```

The script builds the app, installs it to `/Applications/Safari Tab Tab.app`, and launches it.

## System impact

- Safari Tab Tab runs as a **menu bar agent** — minimal CPU usage (no polling, only Safari events).
- Tab history is stored locally in an App Group.

## Project structure

```
SafariTabTab/                 — menu bar app + picker
SafariTabTab Extension/       — Safari extension + content.js
Shared/                       — MRU store
Scripts/reinstall.sh          — build + install
```

## Bundle identifiers

| Target | Bundle ID |
|--------|-----------|
| App | `com.1kub.safaritabtab` |
| Extension | `com.1kub.safaritabtab.extension` |
| App Group | `group.com.1kub.safaritabtab` |

> After renaming bundle IDs, remove any previous build from `/Applications` and re-enable the extension in Safari.

## License

MIT — see [LICENSE](LICENSE).
