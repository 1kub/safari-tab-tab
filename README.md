# Safari Tab Tab

A lightweight Safari extension for **MRU tab switching** with `Control+Tab` (Firefox / Alt+Tab style behavior).

- macOS 13+
- Native Swift, no network calls, no analytics
- Background agent (no Dock icon, no menu bar clutter)
- Open source (MIT)

## Quick install

```bash
git clone https://github.com/1kub/safari-tab-tab.git ~/Documents/safari-tab-tab
cd ~/Documents/safari-tab-tab
chmod +x Scripts/install.sh
./Scripts/install.sh --setup    # one-time: Xcode signing (~1 min)
./Scripts/install.sh            # build + install + open Safari settings
```

Then in Safari (2 clicks):
1. Turn on **Safari Tab Tab Extension**
2. **Always Allow on Every Website**

Keep the **Switch Tab** button in the Safari toolbar.

## What `install.sh` does for you

- Builds the app with automatic provisioning (`-allowProvisioningUpdates`)
- Installs to `/Applications/Safari Tab Tab.app`
- Launches the app
- Opens **Safari → Extensions** settings
- Removes quarantine flags when possible

## One-time Xcode signing

Required once per Mac (free Apple ID is enough):

```bash
./Scripts/install.sh --setup
```

In Xcode: set **Team** on both targets → press **⌘B** once.

Optional — skip Xcode next time by saving your Team ID:

```bash
echo YOUR_TEAM_ID > .xcode-team
```

Find Team ID in Xcode → Settings → Accounts → your Apple ID → Team ID.

## Re-install after 7 days (free Apple ID)

```bash
./Scripts/install.sh
```

To stop the background app: `pkill -x "Safari Tab Tab"`

## Behavior

| Action | Result |
|--------|--------|
| Quick `Ctrl+Tab` | Switch to the previous (MRU) tab |
| Hold `Ctrl+Tab` ~0.2s | Show a picker of recent tabs |
| `Ctrl+Tab` while picker is open | Move forward in history |
| `Ctrl+Shift+Tab` | Move backward in history |
| Release `Ctrl` | Switch to the selected tab |

## What cannot be automated (Apple limits)

- Enabling the extension in Safari — you must click it once
- Free signing expires every ~7 days — re-run `install.sh`
- App Store install without a paid Developer account ($99/year)

## Bundle identifiers

| Target | Bundle ID |
|--------|-----------|
| App | `com.1kub.safaritabtab` |
| Extension | `com.1kub.safaritabtab.extension` |
| App Group | `group.com.1kub.safaritabtab` |

## License

MIT — see [LICENSE](LICENSE).
