import SwiftUI

private enum Theme {
    static let bg = Color(red: 0.03, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let line = Color(red: 0.16, green: 0.20, blue: 0.27)
    static let text = Color.white
    static let muted = Color.white.opacity(0.55)
    static let cyan = Color(red: 0.24, green: 0.88, blue: 1.0)
    static let green = Color(red: 0.24, green: 1.0, blue: 0.60)
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.13)
}

private struct SizePreset: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let width: Int
    let height: Int
}

struct ContentView: View {
    @AppStorage("width") private var widthText = ""
    @AppStorage("height") private var heightText = ""
    @AppStorage("stretch") private var stretch = true
    @AppStorage("lastBundle") private var lastBundle = ""

    @State private var apps: [LaunchableApp] = []
    @State private var query = ""
    @State private var selected: LaunchableApp?
    @State private var status = "Set stretch, apply size, then launch a game."
    @State private var statusError = false
    @State private var presetTitle = "Native"

    private var nativeWidth: Int { ResolutionCanvas.nativeWidth() }
    private var nativeHeight: Int { ResolutionCanvas.nativeHeight() }

    private var presets: [SizePreset] {
        var items: [SizePreset] = [
            .init(title: "Native", width: nativeWidth, height: nativeHeight),
            .init(title: "1440 x 1080  (4:3 stretch)", width: 1440, height: 1080),
            .init(title: "1280 x 960  (4:3 stretch)", width: 1280, height: 960),
            .init(title: "1280 x 1024  (5:4)", width: 1280, height: 1024),
            .init(title: "1920 x 1080  (16:9)", width: 1920, height: 1080),
            .init(title: "1600 x 900  (16:9)", width: 1600, height: 900),
            .init(title: "1280 x 720  (16:9)", width: 1280, height: 720),
            .init(title: "1024 x 768  (4:3)", width: 1024, height: 768),
            .init(title: "960 x 720  (4:3)", width: 960, height: 720),
        ]
        let native = (nativeWidth, nativeHeight)
        if !items.contains(where: { ($0.width, $0.height) == native }) {
            items.insert(.init(title: "\(nativeWidth) x \(nativeHeight)", width: nativeWidth, height: nativeHeight), at: 1)
        }
        return items
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
                    VStack(alignment: .leading, spacing: 18) {
                        dimensionsCard
                        gameCard
                        buttons
                        Text(status)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(statusError ? Color.red.opacity(0.95) : Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: setup)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("by sonic")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.cyan)
            Text("RESOLUTION LAUNCHER")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Theme.text)
            Rectangle()
                .fill(Theme.cyan)
                .frame(height: 2)
                .padding(.top, 8)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private var dimensionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("DIMENSIONS")
            HStack(spacing: 10) {
                numberField("Width", text: $widthText)
                numberField("Height", text: $heightText)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Preset")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.muted)
                Menu {
                    ForEach(presets) { item in
                        Button(item.title) {
                            presetTitle = item.title
                            widthText = String(item.width)
                            heightText = String(item.height)
                        }
                    }
                } label: {
                    HStack {
                        Text(presetTitle)
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Theme.cyan)
                    }
                    .padding(12)
                    .background(Theme.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.line, lineWidth: 1)
                    )
                }
            }
            Toggle(isOn: $stretch) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stretch")
                        .foregroundStyle(Theme.text)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Fill the screen. Image may distort.")
                        .foregroundStyle(Theme.muted)
                        .font(.system(size: 12))
                }
            }
            .tint(Theme.cyan)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var gameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("GAME")
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                TextField("Search games", text: $query)
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(Theme.text)
            }
            .padding(10)
            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if let selected {
                Text("Selected: \(selected.name)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.cyan)
            }

            VStack(spacing: 0) {
                ForEach(filtered.prefix(40)) { app in
                    Button {
                        selected = app
                        lastBundle = app.bundleID
                        setStatus("Selected \(app.name). Apply dimensions, then launch.")
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .foregroundStyle(Theme.text)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(app.bundleID)
                                    .foregroundStyle(Theme.muted)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                            }
                            Spacer()
                            if selected?.bundleID == app.bundleID {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.cyan)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    if app.bundleID != filtered.prefix(40).last?.bundleID {
                        Rectangle().fill(Theme.line).frame(height: 1)
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            actionButton("Apply Dimensions", color: Theme.cyan, text: .black) { _ = applyDimensions() }
            actionButton("Launch Game", color: Theme.green, text: .black, action: launchGame)
            actionButton("Restore Display", color: Theme.amber, text: .black, action: restoreDisplay)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(Theme.muted)
    }

    private func numberField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.muted)
            TextField(title, text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.text)
                .padding(.vertical, 10)
                .background(Theme.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.line, lineWidth: 1)
                )
        }
    }

    private func actionButton(_ title: String, color: Color, text: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func setup() {
        if widthText.isEmpty { widthText = String(nativeWidth) }
        if heightText.isEmpty { heightText = String(nativeHeight) }
        apps = AppLauncher.installedApps()
        selected = apps.first(where: { $0.bundleID == lastBundle })
            ?? apps.first(where: { $0.bundleID.contains("callofduty") || $0.name.localizedCaseInsensitiveContains("call of duty") })
        if let selected {
            lastBundle = selected.bundleID
        }
        syncPresetTitle()
        setStatus("Native \(nativeWidth) x \(nativeHeight). Pick size, stretch, then a game.")
    }

    private func syncPresetTitle() {
        let width = Int(widthText) ?? nativeWidth
        let height = Int(heightText) ?? nativeHeight
        if let match = presets.first(where: { $0.width == width && $0.height == height }) {
            presetTitle = match.title
        } else {
            presetTitle = "Custom  \(width) x \(height)"
        }
    }

    private func parsedSize() -> (Int, Int)? {
        guard let width = Int(widthText.trimmingCharacters(in: .whitespaces)),
              let height = Int(heightText.trimmingCharacters(in: .whitespaces))
        else {
            setStatus("Width and height must be numbers.", error: true)
            return nil
        }
        return (width, height)
    }

    @discardableResult
    private func applyDimensions() -> Bool {
        guard let (width, height) = parsedSize() else { return false }
        syncPresetTitle()
        do {
            try ResolutionCanvas.applyWidth(width, height: height, stretch: stretch)
            setStatus("Applied \(width) x \(height)\(stretch ? " stretch" : "").")
            return true
        } catch {
            setStatus(error.localizedDescription, error: true)
            return false
        }
    }

    private func launchGame() {
        guard let selected else {
            setStatus("Select a game first.", error: true)
            return
        }
        let applied = applyDimensions()
        AppLauncher.open(selected)
        if applied {
            setStatus("Opening \(selected.name) at \(widthText) x \(heightText)\(stretch ? " stretch" : "").")
        } else {
            setStatus("iOS blocked the resolution change. Opening \(selected.name) at native size.", error: true)
        }
    }

    private func restoreDisplay() {
        widthText = String(nativeWidth)
        heightText = String(nativeHeight)
        stretch = false
        syncPresetTitle()
        do {
            try ResolutionCanvas.restoreNative()
            setStatus("Restored native \(nativeWidth) x \(nativeHeight).")
        } catch {
            setStatus(error.localizedDescription, error: true)
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
