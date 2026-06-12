import Foundation

enum TabCommandRelay {
    static let darwinNotification = "com.1kub.safaritabtab.command"

    struct Payload: Codable {
        let command: String
        let backward: Bool
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SafariTabTabConstants.appGroupID) ?? .standard
    }

    static func send(command: String, backward: Bool = false) {
        let payload = Payload(command: command, backward: backward)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: SafariTabTabConstants.StoreKey.pendingCommand)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(darwinNotification as CFString),
            nil,
            nil,
            true
        )
    }

    static func takePending() -> Payload? {
        guard let data = defaults.data(forKey: SafariTabTabConstants.StoreKey.pendingCommand) else {
            return nil
        }
        defaults.removeObject(forKey: SafariTabTabConstants.StoreKey.pendingCommand)
        return try? JSONDecoder().decode(Payload.self, from: data)
    }
}
