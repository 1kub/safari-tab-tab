import AppKit
import Foundation

enum ExtensionInstallGuard {
    static func verifyOnLaunch() {
        let appPaths = installedAppPaths()
        guard appPaths.count > 1 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let list = appPaths.map { "• \($0)" }.joined(separator: "\n")
            let alert = NSAlert()
            alert.messageText = "Nájdených viac kópií Safari Tab Tab"
            alert.informativeText = """
            Safari môže zobraziť viacero rozšírení. Nechajte len jednu inštaláciu v /Applications.

            \(list)

            V Safari → Nastavenia → Rozšírenia odinštalujte všetky kópie „Safari Tab Tab Extension“, potom v Termináli spustite:
            ./Scripts/install.sh
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private static func installedAppPaths() -> [String] {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        task.arguments = ["kMDItemCFBundleIdentifier == 'com.1kub.safaritabtab'"]
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return fallbackAppPaths()
        }

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let paths = output
            .split(separator: "\n")
            .map { String($0) }
            .filter { $0.hasSuffix(".app") }

        return paths.isEmpty ? fallbackAppPaths() : Array(Set(paths)).sorted()
    }

    private static func fallbackAppPaths() -> [String] {
        let candidates = [
            "/Applications/Safari Tab Tab.app",
            "/Applications/TabTab.app",
        ]
        return candidates.filter { FileManager.default.fileExists(atPath: $0) }
    }
}
