import Foundation

enum TabTabConstants {
    static let appGroupID = "group.local.tabtab.shared"
    static let extensionBundleID = "local.tabtab.extension"
    static let freeProvisioningDays = 7

    enum NotificationName {
        static let pickerOpen = "local.tabtab.pickerOpen"
        static let pickerStep = "local.tabtab.pickerStep"
        static let pickerCommit = "local.tabtab.pickerCommit"
        static let pickerCancel = "local.tabtab.pickerCancel"
        static let historyUpdated = "local.tabtab.historyUpdated"
    }

    enum ExtensionCommand: String {
        case activateTab = "activateTab"
    }

    enum StoreKey {
        static let installDate = "installDate"
        static let windows = "windows"
    }
}
