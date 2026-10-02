import CoreMedia
import ReplayKit

@objc(SampleHandler)
final class SampleHandler: RPBroadcastSampleHandler {
    private let encoder = H264Encoder()
    private let server = USBStreamServer(port: 17421)

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        server.start()
        encoder.onEncodedNAL = { [weak self] data, isKey in
            self?.server.send(annexB: data, isKey: isKey)
        }
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        encoder.encode(sampleBuffer)
    }

    override func broadcastPaused() {}

    override func broadcastResumed() {}

    override func broadcastFinished() {
        encoder.stop()
        server.stop()
    }
}
