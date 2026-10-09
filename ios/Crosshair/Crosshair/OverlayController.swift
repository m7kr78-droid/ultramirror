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

        let pipVC = OverlayPiPViewController(style: style)
        pipVC.view.backgroundColor = .clear
        pipVC.preferredContentSize = CGSize(width: 120, height: 120)

        let host = UIViewController()
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false
        let source = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        source.backgroundColor = .clear
        host.view.addSubview(source)
        root.addSubview(host.view)
        host.didMove(toParent: nil)
        hostController = host

        let content = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: source,
            contentViewController: pipVC
        )
        let controller = AVPictureInPictureController(contentSource: content)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        pip = controller

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            controller.startPictureInPicture()
            self?.isActive = true
            self?.status = "Overlay on. Open your game, then drag the window to the center."
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
        status = "Overlay on. Open your game, then drag the window to the center."
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
    private var hosting: UIHostingController<CrosshairCanvas>?

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
        let canvas = CrosshairCanvas(style: style, previewBackground: false)
        let host = UIHostingController(rootView: canvas)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
        hosting = host
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
