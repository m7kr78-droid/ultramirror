import SwiftUI

private enum Theme {
    static let bg = Color(red: 0.03, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let line = Color(red: 0.16, green: 0.20, blue: 0.27)
    static let text = Color.white
    static let muted = Color.white.opacity(0.55)
    static let cyan = Color(red: 0.24, green: 0.88, blue: 1.0)
    static let green = Color(red: 0.24, green: 1.0, blue: 0.60)
}

struct ContentView: View {
    @AppStorage("dns") private var dnsID = DNSChoice.cloudflare.rawValue
    @AppStorage("host") private var host = "1.1.1.1"
    @State private var apps: [LaunchableApp] = []
    @State private var query = ""
    @State private var selected: LaunchableApp?
    @State private var status = "Apply DNS, test the connection, then launch a game."
    @State private var statusError = false
    @State private var testing = false

    private var dns: DNSChoice {
        DNSChoice(rawValue: dnsID) ?? .cloudflare
    }

    private var filtered: [LaunchableApp] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(text) || $0.bundleID.localizedCaseInsensitiveContains(text)
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        connectionCard
                        gameCard
                        actions
                        Text(status)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(statusError ? Color.red.opacity(0.95) : Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            apps = AppLauncher.installedApps()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("by sonic")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.cyan)
            Text("PING TUNE")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.6)
            Rectangle().fill(Theme.cyan).frame(height: 2).padding(.top, 8)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONNECTION")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            Picker("DNS", selection: $dnsID) {
                ForEach(DNSChoice.allCases) { item in
                    Text(item.title).tag(item.rawValue)
                }
            }
            .pickerStyle(.segmented)
            TextField("Host", text: $host)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text("DNS is the tweak iOS allows. It does not change the ping number inside a game.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var gameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GAME")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                TextField("Search games", text: $query)
                    .textInputAutocapitalization(.never)
            }
            .padding(10)
            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            if filtered.isEmpty {
                Text("No games found.")
                    .foregroundStyle(Theme.muted)
            }
            ForEach(filtered) { app in
                Button {
                    selected = app
                    setStatus("Selected \(app.name).")
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name).foregroundStyle(Theme.text).font(.system(size: 16, weight: .semibold))
                            Text(app.bundleID).foregroundStyle(Theme.muted).font(.system(size: 11)).lineLimit(1)
                        }
                        Spacer()
                        if selected?.bundleID == app.bundleID {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.cyan)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actions: some View {
        VStack(spacing: 10) {
            button("Apply DNS", color: Theme.cyan, text: .black) {
                setStatus("Opening the profile...")
                ConnectionTune.installDNS(dns) { error in
                    if let error {
                        setStatus(error, error: true)
                    } else {
                        setStatus("Tap Allow. Then Settings, General, VPN & Device Management, and install by sonic.")
                    }
                }
            }
            button(testing ? "Testing..." : "Test Connection", color: Theme.card, text: Theme.text) {
                guard !testing else { return }
                testing = true
                setStatus("Connecting to \(host)...")
                ConnectionTune.measure(host: host) { ms in
                    testing = false
                    if let ms {
                        setStatus("\(host): \(ms) ms to connect.")
                    } else {
                        setStatus("No reply from \(host).", error: true)
                    }
                }
            }
            button("Launch Game", color: Theme.green, text: .black) {
                guard let selected else {
                    setStatus("Select a game first.", error: true)
                    return
                }
                if AppLauncher.open(selected) {
                    setStatus("Opening \(selected.name).")
                } else {
                    setStatus("\(selected.name) is not installed, so it cannot open.", error: true)
                }
            }
        }
    }

    private func button(_ title: String, color: Color, text: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func setStatus(_ text: String, error: Bool = false) {
        status = text
        statusError = error
    }
}

#Preview {
    ContentView()
}
