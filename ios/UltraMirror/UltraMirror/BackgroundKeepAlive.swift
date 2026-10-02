import AVFoundation
import Foundation

final class BackgroundKeepAlive {
    static let shared = BackgroundKeepAlive()
    private var player: AVAudioPlayer?

    private init() {}

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
