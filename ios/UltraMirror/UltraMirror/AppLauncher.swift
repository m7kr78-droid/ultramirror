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

        for app in workspaceApps() {
            found[app.bundleID] = app
        }

        for app in catalog {
            if found[app.bundleID] == nil {
                found[app.bundleID] = app
            }
        }

        return found.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func open(_ app: LaunchableApp) {
        if openWithWorkspace(bundleID: app.bundleID) {
            return
        }
        if let scheme = app.urlScheme, let url = URL(string: scheme) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    private static func isInstalled(_ app: LaunchableApp) -> Bool {
        if let scheme = app.urlScheme, let url = URL(string: scheme) {
            return UIApplication.shared.canOpenURL(url)
        }
        return workspaceHas(bundleID: app.bundleID)
    }

    private static func workspace() -> NSObject? {
        guard let cls = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type else { return nil }
        let selector = NSSelectorFromString("defaultWorkspace")
        guard cls.responds(to: selector) else { return nil }
        return cls.perform(selector)?.takeUnretainedValue() as? NSObject
    }

    private static func workspaceApps() -> [LaunchableApp] {
        guard let space = workspace() else { return [] }
        let selector = NSSelectorFromString("allInstalledApplications")
        guard space.responds(to: selector),
              let proxies = space.perform(selector)?.takeUnretainedValue() as? [NSObject]
        else { return [] }

        var apps: [LaunchableApp] = []
        for proxy in proxies {
            let bundleID = selString(proxy, "applicationIdentifier")
            let name = selString(proxy, "localizedName")
            let type = selString(proxy, "applicationType")
            guard !bundleID.isEmpty else { continue }
            if bundleID.hasPrefix("com.apple.") { continue }
            if bundleID == Bundle.main.bundleIdentifier { continue }
            if type == "System" { continue }
            apps.append(LaunchableApp(name: name.isEmpty ? bundleID : name, bundleID: bundleID, urlScheme: nil))
        }
        return apps
    }

    private static func workspaceHas(bundleID: String) -> Bool {
        workspaceApps().contains { $0.bundleID == bundleID }
    }

    private static func openWithWorkspace(bundleID: String) -> Bool {
        guard let space = workspace() else { return false }
        let selector = NSSelectorFromString("openApplicationWithBundleID:")
        guard space.responds(to: selector) else { return false }
        _ = space.perform(selector, with: bundleID)
        return true
    }

    private static func selString(_ object: NSObject, _ name: String) -> String {
        let selector = NSSelectorFromString(name)
        guard object.responds(to: selector) else { return "" }
        return object.perform(selector)?.takeUnretainedValue() as? String ?? ""
    }

    private static let catalog: [LaunchableApp] = [
        .init(name: "Call of Duty", bundleID: "com.activision.callofduty.shooter", urlScheme: "codmobile://"),
        .init(name: "Call of Duty Warzone", bundleID: "com.activision.callofduty.warzone", urlScheme: "codwarzone://"),
        .init(name: "PUBG Mobile", bundleID: "com.tencent.ig", urlScheme: "tencentlaunch1106467070://"),
        .init(name: "Fortnite", bundleID: "com.epicgames.fortnite", urlScheme: "fortnite://"),
        .init(name: "Roblox", bundleID: "com.roblox.robloxmobile", urlScheme: "roblox://"),
        .init(name: "Minecraft", bundleID: "com.mojang.minecraftpe", urlScheme: "minecraft://"),
        .init(name: "Genshin Impact", bundleID: "com.miHoYo.GenshinImpact", urlScheme: "yuanshengame://"),
        .init(name: "Honkai Star Rail", bundleID: "com.HoYoverse.Nap", urlScheme: "hkrpg://"),
        .init(name: "Clash of Clans", bundleID: "com.supercell.magic", urlScheme: "clashofclans://"),
        .init(name: "Clash Royale", bundleID: "com.supercell.scroll", urlScheme: "clashroyale://"),
        .init(name: "Brawl Stars", bundleID: "com.supercell.laser", urlScheme: "brawlstars://"),
        .init(name: "Free Fire", bundleID: "com.dts.freefireth", urlScheme: "freefire://"),
        .init(name: "Mobile Legends", bundleID: "com.mobile.legends", urlScheme: "mobilelegends://"),
        .init(name: "eFootball", bundleID: "jp.konami.pesam", urlScheme: "efootball://"),
        .init(name: "EA FC", bundleID: "com.ea.ios.fifaultimate", urlScheme: "easportsfc://"),
        .init(name: "Among Us", bundleID: "com.innersloth.amongus", urlScheme: "amongus://"),
        .init(name: "TikTok", bundleID: "com.zhiliaoapp.musically", urlScheme: "tiktok://"),
        .init(name: "YouTube", bundleID: "com.google.ios.youtube", urlScheme: "youtube://"),
        .init(name: "Instagram", bundleID: "com.burbn.instagram", urlScheme: "instagram://"),
        .init(name: "WhatsApp", bundleID: "net.whatsapp.WhatsApp", urlScheme: "whatsapp://"),
        .init(name: "Snapchat", bundleID: "com.toyopagroup.picaboo", urlScheme: "snapchat://"),
        .init(name: "Discord", bundleID: "com.hammerandchisel.discord", urlScheme: "discord://"),
        .init(name: "Telegram", bundleID: "ph.telegra.Telegraph", urlScheme: "tg://"),
        .init(name: "Spotify", bundleID: "com.spotify.client", urlScheme: "spotify://"),
        .init(name: "Netflix", bundleID: "com.netflix.Netflix", urlScheme: "nflx://"),
        .init(name: "Safari", bundleID: "com.apple.mobilesafari", urlScheme: "http://"),
        .init(name: "Photos", bundleID: "com.apple.mobileslideshow", urlScheme: "photos-redirect://"),
        .init(name: "Settings", bundleID: "com.apple.Preferences", urlScheme: "App-Prefs://"),
        .init(name: "AltStore", bundleID: "com.rileytestut.AltStore", urlScheme: "altstore://"),
    ]
}
