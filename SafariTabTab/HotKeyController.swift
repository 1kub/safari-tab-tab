import AppKit
import Carbon
import SafariServices

/// Global Control+Tab via Carbon RegisterEventHotKey (no Accessibility needed).
final class HotKeyController {
    static let shared = HotKeyController()

    private var hotKeyRef: EventHotKeyRef?
    private var holdTimer: Timer?
    private var pickerVisible = false
    private var controlDown = false

    private init() {
        registerHotKey()
        installModifierMonitor()
    }

    private func registerHotKey() {
        guard hotKeyRef == nil else { return }

        let hotKeyID = EventHotKeyID(signature: OSType(0x5354_5454), id: 1)
        var eventType = EventTypeSpec(eventClass: UInt32(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ -> OSStatus in
                DispatchQueue.main.async { HotKeyController.shared.onHotKeyPressed() }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        RegisterEventHotKey(UInt32(kVK_Tab), UInt32(controlKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private func installModifierMonitor() {
        var eventType = EventTypeSpec(eventClass: UInt32(kEventClassKeyboard), eventKind: UInt32(kEventRawKeyModifiersChanged))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var modifiers: UInt32 = 0
                GetEventParameter(event, UInt32(kEventParamKeyModifiers), UInt32(typeUInt32), nil, MemoryLayout<UInt32>.size, nil, &modifiers)
                let isDown = (modifiers & UInt32(controlKey)) != 0
                DispatchQueue.main.async { HotKeyController.shared.onControlKeyChanged(isDown: isDown) }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }

    private func onHotKeyPressed() {
        guard isSafariFrontmost else { return }
        controlDown = true

        if pickerVisible {
            dispatchCommand("pickerStep", backward: NSEvent.modifierFlags.contains(.shift))
            return
        }

        // Switch immediately on each Ctrl+Tab press
        dispatchCommand("quickSwitch")

        // Hold Ctrl+Tab to open picker
        cancelHoldTimer()
        let timer = Timer(timeInterval: 0.35, repeats: false) { [weak self] _ in
            guard let self, self.controlDown else { return }
            self.pickerVisible = true
            self.dispatchCommand("pickerOpen", backward: NSEvent.modifierFlags.contains(.shift))
        }
        RunLoop.main.add(timer, forMode: .common)
        holdTimer = timer
    }

    private func onControlKeyChanged(isDown: Bool) {
        if controlDown && !isDown {
            cancelHoldTimer()
            if pickerVisible {
                pickerVisible = false
                dispatchCommand("pickerCommit")
            }
        }
        controlDown = isDown
    }

    private func cancelHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }

    private var isSafariFrontmost: Bool {
        guard let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return id == "com.apple.Safari" || id == "com.apple.SafariTechnologyPreview"
    }

    private func dispatchCommand(_ name: String, backward: Bool = false) {
        Task {
            do {
                try await SFSafariApplication.dispatchMessage(
                    withName: name,
                    toExtensionWithIdentifier: SafariTabTabConstants.extensionBundleID,
                    userInfo: backward ? ["backward": true] : nil
                )
            } catch {
                NSLog("SafariTabTab: dispatchMessage(\(name)) failed: \(error)")
            }
        }
    }
}
