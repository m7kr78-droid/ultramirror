import ReplayKit
import SwiftUI

struct ContentView: View {
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

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("مرآة USB")
                        .font(.system(size: 36, weight: .bold))
                    Text("1080p · 60FPS · كيبل الشحن")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 14) {
                    step(number: "1", text: "اربط الآيفون بالكمبيوتر بكابل الشحن.")
                    step(number: "2", text: "افتح برنامج UltraMirror على الويندوز.")
                    step(number: "3", text: "اضغط زر البث تحت، واختر مرآة USB.")
                    step(number: "4", text: "بعد ما يبدأ البث، ادخل اللعبة عادي.")
                }
                .padding(20)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                BroadcastStartButton()
                    .frame(width: 88, height: 88)

                Text("اضغط الزر الأحمر لبدء نقل الشاشة")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Text("التأخير يعتمد على الكابل والمعالج. صفر تأخير غير ممكن، وهذا أقل تأخير عملي على USB.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 18)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
    }

    private func step(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(width: 28, height: 28)
                .background(Color.red.opacity(0.9), in: Circle())
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
            Spacer(minLength: 0)
        }
    }
}

struct BroadcastStartButton: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
        picker.preferredExtension = "com.ultramirror.app.broadcast"
        picker.showsMicrophoneButton = false
        picker.backgroundColor = .clear
        if let button = picker.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.imageView?.tintColor = .white
            button.tintColor = .white
            button.backgroundColor = UIColor(red: 0.86, green: 0.15, blue: 0.18, alpha: 1)
            button.layer.cornerRadius = 44
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
