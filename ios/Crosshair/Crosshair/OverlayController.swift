import AVFoundation
import AVKit
import SwiftUI
import UIKit

final class OverlayController: NSObject, ObservableObject {
    static let shared = OverlayController()

    @Published var isActive = false
    @Published var status = "Pick a reticle, then start overlay."

    private var pip: AVPictureInPictureController?
    private var hostController: UIViewController?
    private var style = CrosshairStyle.default

    func apply(_ style: CrosshairStyle) {
        self.style = style
        if isActive {
            start(style: style)
        }
    }

    func start(style: CrosshairStyle) {
        self.style = style
        KeepAlive.shared.start()
        stop()

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status = "This iPhone does not allow Picture in Picture overlay."
            return
        }

        guard let root = Self.keyWindow() else {
            status = "Could not start overlay."
            return
        }

        let pipVC = OverlayPiPViewController(style: style.asDot)
        pipVC.view.backgroundColor = .clear
        pipVC.view.isOpaque = false
        pipVC.preferredContentSize = CGSize(width: 36, height: 36)

        let host = UIViewController()
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false
        let side: CGFloat = 36
        let source = UIView(frame: CGRect(
            x: (root.bounds.width - side) / 2,
            y: (root.bounds.height - side) / 2,
            width: side,
            height: side
        ))
        source.backgroundColor = .clear
        source.isOpaque = false
        host.view.addSubview(source)
        root.addSubview(host.view)
        hostController = host

        let content = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: source,
            contentViewController: pipVC
        )
        let controller = AVPictureInPictureController(contentSource: content)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        pip = controller

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            controller.startPictureInPicture()
            self?.isActive = true
            self?.status = "Dot is on, centered. Open the game."
            self?.keepCentered()
        }
    }

    private func keepCentered() {
        for delay in [0.4, 0.8, 1.2, 1.8, 2.6] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                Self.centerOverlayWindows()
            }
        }
    }

    private static func centerOverlayWindows() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            let screen = scene.screen.bounds
            for window in scene.windows {
                let name = NSStringFromClass(type(of: window))
                let looksLikeOverlay = name.contains("PictureInPicture") || name.contains("PGHosted") || name.contains("AVKit")
                guard looksLikeOverlay, window.frame.width < screen.width * 0.6 else { continue }
                window.backgroundColor = .clear
                window.isOpaque = false
                let size = window.frame.size
                window.frame.origin = CGPoint(
                    x: (screen.width - size.width) / 2,
                    y: (screen.height - size.height) / 2
                )
            }
        }
    }

    func stop() {
        pip?.stopPictureInPicture()
        pip = nil
        hostController?.view.removeFromSuperview()
        hostController = nil
        isActive = false
    }

    private static func keyWindow() -> UIView? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}

extension OverlayController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isActive = true
        status = "Dot is on, centered. Open the game."
        Self.centerOverlayWindows()
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isActive = false
        status = "Overlay stopped."
        hostController?.view.removeFromSuperview()
        hostController = nil
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        isActive = false
        status = "iOS blocked a full-screen overlay. Use Start Overlay, then switch to the game. Some games hide Picture in Picture."
    }
}

final class OverlayPiPViewController: AVPictureInPictureVideoCallViewController {
    private let style: CrosshairStyle
    private let dot = CenterDotView()

    init(style: CrosshairStyle) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.dotColor = UIColor(style.color)
        dot.diameter = CGFloat(min(max(style.thickness * 3.2, 4), 14))
        view.addSubview(dot)
        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dot.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dot.topAnchor.constraint(equalTo: view.topAnchor),
            dot.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        clearBackgrounds(from: view)
    }

    private func clearBackgrounds(from view: UIView) {
        view.backgroundColor = .clear
        view.isOpaque = false
        view.subviews.forEach(clearBackgrounds)
    }
}

final class CenterDotView: UIView {
    var dotColor: UIColor = .green
    var diameter: CGFloat = 8

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let side = min(diameter, min(bounds.width, bounds.height) * 0.45)
        let circle = UIBezierPath(ovalIn: CGRect(
            x: bounds.midX - side / 2,
            y: bounds.midY - side / 2,
            width: side,
            height: side
        ))
        dotColor.setFill()
        circle.fill()
    }
}

private extension CrosshairStyle {
    var asDot: CrosshairStyle {
        var copy = self
        copy.shape = .microDot
        copy.outline = false
        return copy
    }
}

final class KeepAlive {
    static let shared = KeepAlive()
    private var player: AVAudioPlayer?

    func start() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(data: Self.silentWav())
            player?.numberOfLoops = -1
            player?.volume = 0.01
            player?.prepareToPlay()
            player?.play()
        } catch {
            return
        }
    }

    private static func silentWav() -> Data {
        let dataSize: UInt32 = 16000
        var data = Data()
        func append(_ value: UInt32) {
            var little = value.littleEndian
            data.append(Data(bytes: &little, count: 4))
        }
        func append16(_ value: UInt16) {
            var little = value.littleEndian
            data.append(Data(bytes: &little, count: 2))
        }
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46])
        append(36 + dataSize)
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20])
        append(16)
        append16(1)
        append16(1)
        append(8000)
        append(8000)
        append16(1)
        append16(8)
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61])
        append(dataSize)
        data.append(Data(repeating: 128, count: Int(dataSize)))
        return data
    }
}
