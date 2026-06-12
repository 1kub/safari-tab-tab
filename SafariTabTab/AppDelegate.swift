import AppKit
import SafariServices

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let picker = PickerPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = TabHistoryStore.installDate()
        setupStatusItem()
        setupNotifications()
        configureActivationPolicy()
    }

    private func configureActivationPolicy() {
        NSApp.setActivationPolicy(.accessory)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "arrow.left.arrow.right.square", accessibilityDescription: "Safari Tab Tab")
        button.image?.isTemplate = true

        let menu = NSMenu()
        menu.addItem(withTitle: statusTitle(), action: nil, keyEquivalent: "")
        menu.items.last?.isEnabled = false
        menu.addItem(.separator())
        menu.addItem(withTitle: "Re-sign App (⌘R)", action: #selector(runReinstall), keyEquivalent: "r")
        menu.addItem(withTitle: "Open Safari Extensions…", action: #selector(openSafariExtensions), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Safari Tab Tab", action: #selector(quit), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    private func setupNotifications() {
        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(handlePickerOpen(_:)), name: Notification.Name(SafariTabTabConstants.NotificationName.pickerOpen), object: nil)
        center.addObserver(self, selector: #selector(handlePickerStep(_:)), name: Notification.Name(SafariTabTabConstants.NotificationName.pickerStep), object: nil)
        center.addObserver(self, selector: #selector(handlePickerCommit(_:)), name: Notification.Name(SafariTabTabConstants.NotificationName.pickerCommit), object: nil)
        center.addObserver(self, selector: #selector(refreshStatusTitle), name: Notification.Name(SafariTabTabConstants.NotificationName.historyUpdated), object: nil)
    }

    private func statusTitle() -> String {
        let days = TabHistoryStore.daysUntilExpiry()
        if days == 0 {
            return "Safari Tab Tab — signature expires today"
        }
        return "Safari Tab Tab — signature expires in \(days) d"
    }

    @objc private func refreshStatusTitle() {
        guard let menu = statusItem?.menu, let item = menu.items.first else { return }
        item.title = statusTitle()
    }

    @objc private func handlePickerOpen(_ notification: Notification) {
        guard let windowID = notification.object as? String else { return }
        let backward = (notification.userInfo?["backward"] as? Bool) ?? false
        DispatchQueue.main.async {
            self.picker.open(for: windowID, backward: backward)
        }
    }

    @objc private func handlePickerStep(_ notification: Notification) {
        let backward = (notification.userInfo?["backward"] as? Bool) ?? false
        DispatchQueue.main.async {
            self.picker.step(backward: backward)
        }
    }

    @objc private func handlePickerCommit(_ notification: Notification) {
        DispatchQueue.main.async {
            self.picker.commitSelection()
        }
    }

    @objc private func runReinstall() {
        guard let scriptURL = Bundle.main.url(forResource: "reinstall", withExtension: "sh") else {
            presentAlert(
                title: "Script not found",
                message: "Run in Terminal:\ncd ~/Documents/safari-tab-tab && ./Scripts/reinstall.sh\n(or open SafariTabTab.xcodeproj and build from Xcode)"
            )
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptURL.path]
        task.environment = ProcessInfo.processInfo.environment.merging([
            "SAFARI_TAB_TAB_PROJECT_DIR": resolveProjectDirectory()
        ]) { _, new in new }

        do {
            try task.run()
            TabHistoryStore.refreshInstallDate()
            refreshStatusTitle()
            presentAlert(
                title: "Re-sign started",
                message: "Build is running in the background. When it finishes, check Safari → Extensions."
            )
        } catch {
            presentAlert(title: "Error", message: error.localizedDescription)
        }
    }

    @objc private func openSafariExtensions() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.Safari.extension") {
            NSWorkspace.shared.open(url)
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Safari.app"))
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }

    private func resolveProjectDirectory() -> String {
        let candidates = [
            NSHomeDirectory() + "/Documents/safari-tab-tab",
            NSHomeDirectory() + "/Documents/tabtabextension",
        ]
        for path in candidates {
            let script = (path as NSString).appendingPathComponent("Scripts/reinstall.sh")
            if FileManager.default.fileExists(atPath: script) {
                return path
            }
        }
        return candidates[0]
    }
}
