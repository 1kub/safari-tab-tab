import SafariServices

final class SafariExtensionHandler: SFSafariExtensionHandler {
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?) {
        Task {
            switch messageName {
            case "quickSwitch":
                await quickSwitch()
            case "pickerOpen":
                let backward = (userInfo?["backward"] as? Bool) ?? false
                await openPicker(backward: backward)
            case "pickerStep":
                let backward = (userInfo?["backward"] as? Bool) ?? false
                notifyPickerStep(backward: backward)
            case "pickerCommit":
                notifyPickerCommit()
            default:
                break
            }
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping (Bool, String) -> Void) {
        Task {
            await TabHistorySync.updateHistory(for: window)
        }
        validationHandler(true, "")
    }

    override func messageReceivedFromContainingApp(withName messageName: String, userInfo: [String: Any]?) {
        guard let command = SafariTabTabConstants.ExtensionCommand(rawValue: messageName) else { return }
        switch command {
        case .activateTab:
            guard let tabID = userInfo?["tabID"] as? Int else { return }
            Task {
                await activateTab(id: tabID)
            }
        }
    }

    override func popoverViewController() -> SFSafariExtensionViewController {
        SafariExtensionViewController.shared
    }

    private func quickSwitch() async {
        guard let window = await SFSafariApplication.activeWindow() else { return }
        let windowID = await TabHistorySync.windowID(for: window)
        await TabHistorySync.updateHistory(for: window)
        guard let tabID = TabHistoryStore.previousTabID(in: windowID) else { return }
        await activateTab(id: tabID, in: window)
    }

    private func openPicker(backward: Bool) async {
        guard let window = await SFSafariApplication.activeWindow() else { return }
        await TabHistorySync.updateHistory(for: window)
        let windowID = await TabHistorySync.windowID(for: window)
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(SafariTabTabConstants.NotificationName.pickerOpen),
            object: windowID,
            userInfo: ["backward": backward],
            deliverImmediately: true
        )
    }

    private func notifyPickerStep(backward: Bool) {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(SafariTabTabConstants.NotificationName.pickerStep),
            object: nil,
            userInfo: ["backward": backward],
            deliverImmediately: true
        )
    }

    private func notifyPickerCommit() {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(SafariTabTabConstants.NotificationName.pickerCommit),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private func activateTab(id: Int) async {
        guard let window = await SFSafariApplication.activeWindow() else { return }
        await activateTab(id: id, in: window)
    }

    private func activateTab(id: Int, in window: SFSafariWindow) async {
        let tabs = await window.allTabs()
        guard tabs.indices.contains(id) else { return }
        await tabs[id].activate()
        await TabHistorySync.recordActivation(tabID: id, in: window)
        SFSafariApplication.setToolbarItemsNeedUpdate()
    }
}

final class SafariExtensionViewController: SFSafariExtensionViewController {
    static let shared = SafariExtensionViewController()
}

enum TabHistorySync {
    static func windowID(for window: SFSafariWindow) async -> String {
        let tabs = await window.allTabs()
        var parts: [String] = []
        for tab in tabs {
            if let page = await tab.activePage(),
               let properties = await page.properties(),
               let url = properties.url?.absoluteString {
                parts.append(url)
            } else {
                parts.append("empty-\(tab.hash)")
            }
        }
        return parts.joined(separator: "|")
    }

    static func updateHistory(for window: SFSafariWindow) async {
        let windowID = await windowID(for: window)
        let safariTabs = await window.allTabs()
        var snapshots: [TabSnapshot] = []
        snapshots.reserveCapacity(safariTabs.count)

        for (index, tab) in safariTabs.enumerated() {
            var title = ""
            var url = ""
            if let page = await tab.activePage(),
               let properties = await page.properties() {
                title = properties.title ?? ""
                url = properties.url?.absoluteString ?? ""
            }
            snapshots.append(TabSnapshot(id: index, title: title, url: url))
        }

        var history = TabHistoryStore.window(for: windowID) ?? WindowHistory(
            windowID: windowID,
            mruTabIDs: [],
            tabs: snapshots
        )

        history.tabs = snapshots
        history.mruTabIDs = history.mruTabIDs.filter { id in
            snapshots.contains(where: { $0.id == id })
        }

        if let activeTab = await window.activeTab(),
           let activeIndex = safariTabs.firstIndex(of: activeTab) {
            history.mruTabIDs.removeAll { $0 == activeIndex }
            history.mruTabIDs.append(activeIndex)
        } else if history.mruTabIDs.isEmpty {
            history.mruTabIDs = snapshots.map(\.id)
        }

        TabHistoryStore.upsert(history)
    }

    static func recordActivation(tabID: Int, in window: SFSafariWindow) async {
        let windowID = await windowID(for: window)
        guard var history = TabHistoryStore.window(for: windowID) else {
            await updateHistory(for: window)
            return
        }
        history.mruTabIDs.removeAll { $0 == tabID }
        history.mruTabIDs.append(tabID)
        TabHistoryStore.upsert(history)
    }
}
