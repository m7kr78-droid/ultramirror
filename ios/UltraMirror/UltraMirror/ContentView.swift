import ReplayKit
import SwiftUI

struct ContentView: View {
    @State private var apps: [LaunchableApp] = []
    @State private var query = ""
    @State private var selected: LaunchableApp?
    @State private var didLaunch = false

    private var filtered: [LaunchableApp] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(text) || $0.bundleID.localizedCaseInsensitiveContains(text)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.08, green: 0.12, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("مرآة USB")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top, 8)

                Text(selected == nil ? "اختر لعبة أو برنامج، بعدين اضغط البث" : "بعد البث راح يفتح: \(selected!.name)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("ابحث عن لعبة أو برنامج", text: $query)
                        .textInputAutocapitalization(.never)
                }
                .padding(10)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)

                List(filtered) { app in
                    Button {
                        selected = app
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
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(selected?.bundleID == app.bundleID ? 0.12 : 0.04))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)

                HStack(spacing: 16) {
                    BroadcastStartButton()
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ابدأ البث")
                            .font(.system(size: 16, weight: .bold))
                        Text("اختر مرآة USB من القائمة")
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
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            launchSelectedIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
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
