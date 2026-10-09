import UIKit

struct LaunchableApp: Identifiable, Hashable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
    let urlScheme: String?
}

enum AppLauncher {
    static func installedApps() -> [LaunchableApp] {
        var found: [String: LaunchableApp] = [:]

        for raw in InstalledApps.userApps() {
            guard let item = raw as? [AnyHashable: Any] else { continue }
            guard let bundleID = item["id"] as? String, !bundleID.isEmpty else { continue }
            if bundleID == Bundle.main.bundleIdentifier { continue }
            if bundleID.hasPrefix("com.apple.") { continue }
            let name = (item["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? bundleID
            found[bundleID] = LaunchableApp(name: name, bundleID: bundleID, urlScheme: nil)
        }

        for app in catalog {
            if let match = found.values.first(where: {
                $0.bundleID == app.bundleID
                    || $0.bundleID.contains(app.bundleID)
                    || $0.name.caseInsensitiveCompare(app.name) == .orderedSame
            }) {
                found[match.bundleID] = LaunchableApp(name: match.name, bundleID: match.bundleID, urlScheme: app.urlScheme)
            } else {
                found[app.bundleID] = app
            }
        }

        var unique: [String: LaunchableApp] = [:]
        for app in found.values {
            if let current = unique[app.name.lowercased()], current.bundleID.count <= app.bundleID.count {
                continue
            }
            unique[app.name.lowercased()] = app
        }
        return unique.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func open(_ app: LaunchableApp) {
        if let scheme = app.urlScheme, let url = URL(string: scheme) {
            UIApplication.shared.open(url)
            return
        }
        var identifiers = [app.bundleID]
        if let team = teamIdentifier(), !app.bundleID.contains(team) {
            identifiers.append("\(team).\(app.bundleID).\(team)")
            identifiers.append("\(team).\(app.bundleID)")
        }
        for identifier in identifiers {
            InstalledApps.openBundleID(identifier)
        }
    }

    private static func teamIdentifier() -> String? {
        guard
            let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        let text = String(data: data, encoding: .isoLatin1) ?? String(decoding: data, as: UTF8.self)
        guard let keyRange = text.range(of: "<key>TeamIdentifier</key>") else { return nil }
        let rest = text[keyRange.upperBound...]
        guard let start = rest.range(of: "<string>"), let end = rest.range(of: "</string>") else { return nil }
        let value = String(rest[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static let catalog: [LaunchableApp] = [
        .init(name: "Call of Duty", bundleID: "com.activision.callofduty.shooter", urlScheme: "codmobile://"),
        .init(name: "Call of Duty Warzone", bundleID: "com.activision.callofduty.warzone", urlScheme: "codwarzone://"),
        .init(name: "PUBG Mobile", bundleID: "com.tencent.ig", urlScheme: "tencentlaunch1106467070://"),
        .init(name: "Fortnite", bundleID: "com.epicgames.fortnite", urlScheme: "fortnite://"),
        .init(name: "Roblox", bundleID: "com.roblox.robloxmobile", urlScheme: "roblox://"),
        .init(name: "Minecraft", bundleID: "com.mojang.minecraftpe", urlScheme: "minecraft://"),
        .init(name: "Genshin Impact", bundleID: "com.miHoYo.GenshinImpact", urlScheme: "yuanshengame://"),
        .init(name: "Free Fire", bundleID: "com.dts.freefireth", urlScheme: "freefire://"),
        .init(name: "Mobile Legends", bundleID: "com.mobile.legends", urlScheme: "mobilelegends://"),
        .init(name: "Clash of Clans", bundleID: "com.supercell.magic", urlScheme: "clashofclans://"),
        .init(name: "Brawl Stars", bundleID: "com.supercell.laser", urlScheme: "brawlstars://"),
        .init(name: "8 Ball Pool", bundleID: "com.miniclip.8ballpool", urlScheme: "eightballpool://"),
        .init(name: "Stumble Guys", bundleID: "com.kitkagames.fallbuddies", urlScheme: "stumbleguys://"),
        .init(name: "EA FC Mobile", bundleID: "com.ea.ios.fifamobile", urlScheme: "fifamobile://"),
        .init(name: "eFootball", bundleID: "com.konami.pes", urlScheme: "efootball://"),
    ]
}
