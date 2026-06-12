import Foundation

enum SafariTabTabConstants {
    static let appGroupID = "group.com.1kub.safaritabtab"
    static let extensionBundleID = "com.1kub.safaritabtab.extension"
    static let freeProvisioningDays = 7

    enum NotificationName {
        static let pickerOpen = "com.1kub.safaritabtab.pickerOpen"
        static let pickerStep = "com.1kub.safaritabtab.pickerStep"
        static let pickerCommit = "com.1kub.safaritabtab.pickerCommit"
        static let pickerCancel = "com.1kub.safaritabtab.pickerCancel"
        static let historyUpdated = "com.1kub.safaritabtab.historyUpdated"
    }

    enum ExtensionCommand: String {
        case activateTab = "activateTab"
    }

    enum StoreKey {
        static let installDate = "installDate"
        static let windows = "windows"
    }
}
