import Foundation

struct TabSnapshot: Codable, Equatable, Identifiable {
    let id: Int
    var title: String
    var url: String

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if !url.isEmpty { return url }
        return "Tab \(id + 1)"
    }
}

struct WindowHistory: Codable, Equatable {
    var windowID: String
    var mruTabIDs: [Int]
    var tabs: [TabSnapshot]

    var mruTabs: [TabSnapshot] {
        let lookup = Dictionary(uniqueKeysWithValues: tabs.map { ($0.id, $0) })
        return mruTabIDs.compactMap { lookup[$0] }
    }
}

struct TabHistoryStore {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: TabTabConstants.appGroupID) ?? .standard
    }

    static func loadWindows() -> [WindowHistory] {
        guard let data = defaults.data(forKey: TabTabConstants.StoreKey.windows) else {
            return []
        }
        return (try? JSONDecoder().decode([WindowHistory].self, from: data)) ?? []
    }

    static func saveWindows(_ windows: [WindowHistory]) {
        guard let data = try? JSONEncoder().encode(windows) else { return }
        defaults.set(data, forKey: TabTabConstants.StoreKey.windows)
        DistributedNotificationCenter.default().post(
            name: Notification.Name(TabTabConstants.NotificationName.historyUpdated),
            object: nil
        )
    }

    static func window(for windowID: String) -> WindowHistory? {
        loadWindows().first { $0.windowID == windowID }
    }

    static func upsert(_ window: WindowHistory) {
        var windows = loadWindows().filter { $0.windowID != window.windowID }
        windows.append(window)
        saveWindows(windows)
    }

    static func previousTabID(in windowID: String) -> Int? {
        guard let window = window(for: windowID) else { return nil }
        guard window.mruTabIDs.count >= 2 else { return nil }
        return window.mruTabIDs[window.mruTabIDs.count - 2]
    }

    static func installDate() -> Date {
        if let stored = defaults.object(forKey: TabTabConstants.StoreKey.installDate) as? Date {
            return stored
        }
        let now = Date()
        defaults.set(now, forKey: TabTabConstants.StoreKey.installDate)
        return now
    }

    static func refreshInstallDate() {
        defaults.set(Date(), forKey: TabTabConstants.StoreKey.installDate)
    }

    static func daysUntilExpiry(from installDate: Date = installDate()) -> Int {
        let elapsed = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return max(0, TabTabConstants.freeProvisioningDays - elapsed)
    }
}
