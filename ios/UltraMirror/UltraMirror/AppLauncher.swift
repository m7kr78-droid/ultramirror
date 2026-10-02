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
            let name = (item["name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? bundleID
            found[bundleID] = LaunchableApp(name: name, bundleID: bundleID, urlScheme: nil)
        }

        let team = teamIdentifier()
        for app in catalog {
            found[app.bundleID] = found[app.bundleID] ?? app
            if let team, !team.isEmpty {
                let sideloaded = "\(team).\(app.bundleID).\(team)"
                if found[sideloaded] == nil {
                    found[sideloaded] = LaunchableApp(name: app.name, bundleID: sideloaded, urlScheme: app.urlScheme)
                }
                let prefixed = "\(team).\(app.bundleID)"
                if found[prefixed] == nil {
                    found[prefixed] = LaunchableApp(name: app.name, bundleID: prefixed, urlScheme: app.urlScheme)
                }
            }
        }

        return found.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func open(_ app: LaunchableApp) {
        var identifiers = [app.bundleID]
        let team = teamIdentifier()
        if let team, !app.bundleID.contains(team) {
            identifiers.append("\(team).\(app.bundleID).\(team)")
            identifiers.append("\(team).\(app.bundleID)")
        }

        for identifier in identifiers {
            if InstalledApps.openBundleID(identifier) {
                return
            }
        }

        if let scheme = app.urlScheme, let url = URL(string: scheme) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    static func teamIdentifier() -> String? {
        guard
            let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
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
        .init(name: "TikTok", bundleID: "com.zhiliaoapp.musically", urlScheme: "tiktok://"),
        .init(name: "YouTube", bundleID: "com.google.ios.youtube", urlScheme: "youtube://"),
        .init(name: "Instagram", bundleID: "com.burbn.instagram", urlScheme: "instagram://"),
        .init(name: "WhatsApp", bundleID: "net.whatsapp.WhatsApp", urlScheme: "whatsapp://"),
        .init(name: "Discord", bundleID: "com.hammerandchisel.discord", urlScheme: "discord://"),
        .init(name: "Telegram", bundleID: "ph.telegra.Telegraph", urlScheme: "tg://"),
        .init(name: "Spotify", bundleID: "com.spotify.client", urlScheme: "spotify://"),
        .init(name: "AltStore", bundleID: "com.rileytestut.AltStore", urlScheme: "altstore://"),
    ]
}
