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

## First-time setup (free Apple ID)

1. Open `TabTab.xcodeproj` in Xcode.
2. In both targets (`TabTab`, `TabTab Extension`), set **Signing & Capabilities** to your Apple ID (Personal Team).
3. Enable **App Groups** with ID `group.local.tabtab.shared` in both targets.
4. Build and install:

```bash
chmod +x Scripts/reinstall.sh
./Scripts/reinstall.sh
```

5. Safari → **Settings → Extensions** → enable **TabTab Extension** → “Always Allow on Every Website”.
6. Keep the TabTab icon in the Safari toolbar (required for reliable operation).

## Re-sign after 7 days (free provisioning)

Without a paid Developer account, the signature expires after about **7 days**.

**From the TabTab menu bar icon:** “Re-sign App” (or in Terminal):

```bash
./Scripts/reinstall.sh
```

The script builds the app, installs it to `/Applications/TabTab.app`, and launches it.

## System impact

- TabTab runs as a **menu bar agent** — minimal CPU usage (no polling, only Safari events).
- Tab history is stored locally in an App Group.

## Project structure

```
TabTab/                 — menu bar app + picker
TabTab Extension/       — Safari extension + content.js
Shared/                 — MRU store
Scripts/reinstall.sh    — build + install
```

## License

MIT — see [LICENSE](LICENSE).
