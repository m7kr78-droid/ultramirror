import ReplayKit
import SwiftUI

struct ContentView: View {
    @State private var apps: [LaunchableApp] = []
    @State private var query = ""
    @State private var selected: LaunchableApp?
    @State private var didLaunch = false
    @State private var capturedSince: Date?
    @State private var status = "أولاً ابدأ البث. لا تفتح اللعبة قبل الشريط الأحمر"

    private var filtered: [LaunchableApp] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(text) || $0.bundleID.localizedCaseInsensitiveContains(text)
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 10) {
                Text("مرآة USB")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top, 8)

                Text("مهم: لا تضغط افتح اللعبة إلا بعد ما يظهر الشريط الأحمر فوق الشاشة")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text(status)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("ابحث عن لعبة", text: $query)
                        .textInputAutocapitalization(.never)
                }
                .padding(10)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)

                List(filtered) { app in
                    Button {
                        selected = app
                        status = "مختار: \(app.name). اضغط البث الأحمر أولاً"
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(app.bundleID)
                                    .foregroundStyle(.white.opacity(0.45))
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                            }
                            Spacer()
                            if selected?.bundleID == app.bundleID {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.red)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(selected?.bundleID == app.bundleID ? 0.12 : 0.04))
                }
                .listStyle(.plain)
                .background(Color.clear)

                HStack(spacing: 16) {
                    BroadcastStartButton()
                        .frame(width: 80, height: 80)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1) ابدأ البث")
                            .font(.system(size: 16, weight: .bold))
                        Text("اضغط الدائرة واختر مرآة USB ثم Start Broadcast")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                Button("2) افتح اللعبة بعد الشريط الأحمر") {
                    guard UIScreen.main.isCaptured else {
                        status = "البث ما بدأ. اضغط الدائرة الحمراء واختر مرآة USB"
                        return
                    }
                    guard let selected else {
                        status = "اختر لعبة من القائمة"
                        return
                    }
                    status = "يفتح \(selected.name)"
                    AppLauncher.open(selected)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .onAppear {
            apps = AppLauncher.installedApps()
            selected = apps.first(where: { $0.bundleID.contains("callofduty") || $0.name.localizedCaseInsensitiveContains("call of duty") })
            status = "اضغط الدائرة الحمراء. لا تفتح كود قبل الشريط الأحمر"
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            launchAfterBroadcastSettles()
        }
    }

    private func launchAfterBroadcastSettles() {
        if !UIScreen.main.isCaptured {
            capturedSince = nil
            didLaunch = false
            return
        }
        if capturedSince == nil {
            capturedSince = Date()
            status = "البث بدأ. انتظر الشريط الأحمر…"
            return
        }
        guard let capturedSince, Date().timeIntervalSince(capturedSince) >= 3 else { return }
        guard let selected, !didLaunch else { return }
        didLaunch = true
        status = "الشريط الأحمر ظاهر، يفتح \(selected.name)"
        AppLauncher.open(selected)
    }
}

struct BroadcastStartButton: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        picker.preferredExtension = Self.extensionBundleID()
        picker.showsMicrophoneButton = false
        picker.backgroundColor = .clear
        if let button = picker.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.imageView?.tintColor = .white
            button.tintColor = .white
            button.backgroundColor = UIColor(red: 0.86, green: 0.15, blue: 0.18, alpha: 1)
            button.layer.cornerRadius = 40
            button.clipsToBounds = true
            button.frame = picker.bounds
        }
        return picker
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}

    private static func extensionBundleID() -> String {
        if let plugins = Bundle.main.builtInPlugInsURL,
           let items = try? FileManager.default.contentsOfDirectory(at: plugins, includingPropertiesForKeys: nil) {
            for item in items where item.pathExtension == "appex" {
                if let bundle = Bundle(url: item), let identifier = bundle.bundleIdentifier {
                    return identifier
                }
            }
        }
        return (Bundle.main.bundleIdentifier ?? "com.ultramirror.app") + ".broadcast"
    }
}

#Preview {
    ContentView()
}
