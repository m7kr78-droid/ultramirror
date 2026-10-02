import CoreMedia
import CoreVideo
import VideoToolbox

final class H264Encoder {
    var onEncodedNAL: ((Data, Bool) -> Void)?

    private var session: VTCompressionSession?
    private var width: Int32 = 0
    private var height: Int32 = 0
    private let encodeQueue = DispatchQueue(label: "com.ultramirror.encode", qos: .userInteractive)
    private var spsPps: Data?
    private var frameCount: Int32 = 0

    private let targetFPS: Int32 = 60
    private let bitrate: Int32 = 20_000_000

    func encode(_ sampleBuffer: CMSampleBuffer) {
        encodeQueue.async { [weak self] in
            self?.encodeOnQueue(sampleBuffer)
        }
    }

    func stop() {
        encodeQueue.sync {
            if let session {
                VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
                VTCompressionSessionInvalidate(session)
            }
            session = nil
            width = 0
            height = 0
            spsPps = nil
            frameCount = 0
        }
    }

    private func encodeOnQueue(_ sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let srcW = Int32(CVPixelBufferGetWidth(imageBuffer))
        let srcH = Int32(CVPixelBufferGetHeight(imageBuffer))

        if session == nil || srcW != width || srcH != height {
            resetSession(width: srcW, height: srcH)
        }
        guard let session else { return }

        frameCount += 1
        let forceKey = frameCount == 1 || frameCount % 60 == 0
        var properties: CFDictionary?
        if forceKey {
            properties = [kVTEncodeFrameOptionKey_ForceKeyFrame: true] as CFDictionary
        }

        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: imageBuffer,
            presentationTimeStamp: pts,
            duration: CMTime(value: 1, timescale: targetFPS),
            frameProperties: properties,
            infoFlagsOut: nil
        )
    }

    private func resetSession(width: Int32, height: Int32) {
        if let session {
            VTCompressionSessionInvalidate(session)
        }
        session = nil
        spsPps = nil
        self.width = width
        self.height = height

        var newSession: VTCompressionSession?
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: [
                kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder: true
            ] as CFDictionary,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: compressionCallback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &newSession
        )
        guard status == noErr, let newSession else { return }

        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_High_AutoLevel)
        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: 60 as CFNumber)
        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: 1 as CFNumber)
        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: targetFPS as CFNumber)
        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrate as CFNumber)
        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_DataRateLimits, value: [bitrate * 2 / 8, 1] as CFArray)
        VTSessionSetProperty(newSession, key: kVTCompressionPropertyKey_Quality, value: 0.8 as CFNumber)
        VTCompressionSessionPrepareToEncodeFrames(newSession)
        session = newSession
    }

    fileprivate func handleOutput(status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) {
        guard status == noErr, let sampleBuffer, CMSampleBufferDataIsReady(sampleBuffer) else { return }
        if infoFlags.contains(.frameDropped) { return }

        let isKey = isKeyframe(sampleBuffer)

        if isKey, let header = parameterSets(from: sampleBuffer) {
            spsPps = header
        }

        guard let annexB = annexB(from: sampleBuffer) else { return }
        var packet = Data()
        if isKey, let spsPps {
            packet.append(spsPps)
        }
        packet.append(annexB)
        onEncodedNAL?(packet, isKey)
    }

    private func isKeyframe(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [Any],
            let dict = attachments.first as? [CFString: Any]
        else {
            return true
        }
        if let notSync = dict[kCMSampleAttachmentKey_NotSync] as? Bool {
            return !notSync
        }
        return true
    }

    private func parameterSets(from sampleBuffer: CMSampleBuffer) -> Data? {
        guard let format = CMSampleBufferGetFormatDescription(sampleBuffer) else { return nil }
        var spsSize = 0
        var ppsSize = 0
        var spsCount = 0
        var ppsCount = 0
        var sps: UnsafePointer<UInt8>?
        var pps: UnsafePointer<UInt8>?
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, parameterSetIndex: 0, parameterSetPointerOut: &sps, parameterSetSizeOut: &spsSize, parameterSetCountOut: &spsCount, nalUnitHeaderLengthOut: nil)
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, parameterSetIndex: 1, parameterSetPointerOut: &pps, parameterSetSizeOut: &ppsSize, parameterSetCountOut: &ppsCount, nalUnitHeaderLengthOut: nil)
        guard let sps, let pps else { return nil }
        var data = Data([0x00, 0x00, 0x00, 0x01])
        data.append(sps, count: spsSize)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
        data.append(pps, count: ppsSize)
        return data
    }

    private func annexB(from sampleBuffer: CMSampleBuffer) -> Data? {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
        guard let dataPointer else { return nil }
        let raw = Data(bytes: dataPointer, count: length)
        return avccToAnnexB(raw)
    }

    private func avccToAnnexB(_ data: Data) -> Data {
        var output = Data()
        var offset = 0
        let startCode = Data([0x00, 0x00, 0x00, 0x01])
        while offset + 4 <= data.count {
            let naluLength = Int(data[offset]) << 24 | Int(data[offset + 1]) << 16 | Int(data[offset + 2]) << 8 | Int(data[offset + 3])
            offset += 4
            guard offset + naluLength <= data.count else { break }
            output.append(startCode)
            output.append(data.subdata(in: offset..<(offset + naluLength)))
            offset += naluLength
        }
        return output
    }
}

private func compressionCallback(
    outputCallbackRefCon: UnsafeMutableRawPointer?,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    status: OSStatus,
    infoFlags: VTEncodeInfoFlags,
    sampleBuffer: CMSampleBuffer?
) {
    guard let outputCallbackRefCon else { return }
    let encoder = Unmanaged<H264Encoder>.fromOpaque(outputCallbackRefCon).takeUnretainedValue()
    encoder.handleOutput(status: status, infoFlags: infoFlags, sampleBuffer: sampleBuffer)
}
