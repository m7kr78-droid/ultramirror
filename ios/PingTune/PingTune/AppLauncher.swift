import UIKit

struct LaunchableApp: Identifiable, Hashable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
}

enum AppLauncher {
    static func installedApps() -> [LaunchableApp] {
        var best: [String: LaunchableApp] = [:]
        for raw in InstalledApps.userApps() {
            guard let item = raw as? [AnyHashable: Any] else { continue }
            guard let bundleID = item["id"] as? String, !bundleID.isEmpty else { continue }
            if bundleID == Bundle.main.bundleIdentifier { continue }
            let name = (item["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? bundleID
            let app = LaunchableApp(name: name, bundleID: bundleID)
            if let current = best[name], current.bundleID.count <= bundleID.count {
                continue
            }
            best[name] = app
        }
        return best.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func open(_ app: LaunchableApp) {
        InstalledApps.openBundleID(app.bundleID)
    }
}
