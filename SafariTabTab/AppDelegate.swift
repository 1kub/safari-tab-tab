import AppKit
import SafariServices
import ServiceManagement

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let picker = PickerPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = TabHistoryStore.installDate()
        _ = HotKeyController.shared
        ExtensionInstallGuard.verifyOnLaunch()
        registerLoginItemIfNeeded()
        setupNotifications()
        NSApp.setActivationPolicy(.accessory)
    }

    private func registerLoginItemIfNeeded() {
        guard #available(macOS 13.0, *) else { return }
        guard SMAppService.mainApp.status != .enabled else { return }
        try? SMAppService.mainApp.register()
    }

    private func setupNotifications() {
        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(handlePickerOpen(_:)), name: Notification.Name(SafariTabTabConstants.NotificationName.pickerOpen), object: nil)
        center.addObserver(self, selector: #selector(handlePickerStep(_:)), name: Notification.Name(SafariTabTabConstants.NotificationName.pickerStep), object: nil)
        center.addObserver(self, selector: #selector(handlePickerCommit(_:)), name: Notification.Name(SafariTabTabConstants.NotificationName.pickerCommit), object: nil)
    }

    @objc private func handlePickerOpen(_ notification: Notification) {
        guard let windowID = notification.object as? String else { return }
        let backward = (notification.userInfo?["backward"] as? Bool) ?? false
        DispatchQueue.main.async { self.picker.open(for: windowID, backward: backward) }
    }

    @objc private func handlePickerStep(_ notification: Notification) {
        let backward = (notification.userInfo?["backward"] as? Bool) ?? false
        DispatchQueue.main.async { self.picker.step(backward: backward) }
    }

    @objc private func handlePickerCommit(_ notification: Notification) {
        DispatchQueue.main.async { self.picker.commitSelection() }
    }
}
