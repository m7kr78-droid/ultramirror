import ReplayKit
import SwiftUI

struct ContentView: View {
    @State private var apps: [LaunchableApp] = []
    @State private var query = ""
    @State private var selected: LaunchableApp?
    @State private var didLaunch = false
    @State private var status = "اختر اللعبة ثم اضغط البث"

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

                Text(status)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("ابحث: كود، تيك توك، يوتيوب...", text: $query)
                        .textInputAutocapitalization(.never)
                }
                .padding(10)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)

                List(filtered) { app in
                    Button {
                        selected = app
                        status = "مختار: \(app.name). اضغط البث الأحمر"
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

                Button("افتح التطبيق الآن") {
                    guard let selected else {
                        status = "اختر لعبة من القائمة أولاً"
                        return
                    }
                    status = "يفتح \(selected.name)…"
                    AppLauncher.open(selected)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)

                HStack(spacing: 16) {
                    BroadcastStartButton()
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ابدأ البث")
                            .font(.system(size: 16, weight: .bold))
                        Text("اختر مرآة USB، وبعدها يفتح التطبيق")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .onAppear {
            apps = AppLauncher.installedApps()
            if let cod = apps.first(where: { $0.name.localizedCaseInsensitiveContains("call of duty") || $0.bundleID.contains("callofduty") }) {
                selected = cod
                status = "مختار: \(cod.name). اضغط البث الأحمر"
            } else {
                status = "وجد \(apps.count) برنامج. اختر واحد ثم اضغط البث"
            }
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            launchSelectedIfNeeded()
        }
    }

    private func launchSelectedIfNeeded() {
        if !UIScreen.main.isCaptured {
            didLaunch = false
            return
        }
        guard let selected, !didLaunch else { return }
        didLaunch = true
        status = "البث شغال، يفتح \(selected.name)…"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AppLauncher.open(selected)
        }
    }
}

struct BroadcastStartButton: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 72, height: 72))
        picker.preferredExtension = (Bundle.main.bundleIdentifier ?? "com.ultramirror.app") + ".broadcast"
        picker.showsMicrophoneButton = false
        picker.backgroundColor = .clear
        if let button = picker.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.imageView?.tintColor = .white
            button.tintColor = .white
            button.backgroundColor = UIColor(red: 0.86, green: 0.15, blue: 0.18, alpha: 1)
            button.layer.cornerRadius = 36
            button.clipsToBounds = true
            button.frame = picker.bounds
        }
        return picker
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}

#Preview {
    ContentView()
}
