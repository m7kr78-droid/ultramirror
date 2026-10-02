import Foundation
import Network

final class StreamRelay {
    static let shared = StreamRelay()

    private let queue = DispatchQueue(label: "com.ultramirror.relay", qos: .userInteractive)
    private var pcListener: NWListener?
    private var extListener: NWListener?
    private var pcConnection: NWConnection?
    private var extConnection: NWConnection?

    private init() {}

    func start() {
        queue.async { [weak self] in
            self?.listen(port: 17420, isPC: true)
            self?.listen(port: 17421, isPC: false)
        }
    }

    private func listen(port: UInt16, isPC: Bool) {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.acceptLocalOnly = false
        let tcp = params.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options
        tcp?.noDelay = true
        tcp?.enableKeepalive = true

        guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!) else { return }
        if isPC {
            pcListener?.cancel()
            pcListener = listener
        } else {
            extListener?.cancel()
            extListener = listener
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.queue.async {
                guard let self else { return }
                if isPC {
                    self.pcConnection?.cancel()
                    self.pcConnection = connection
                } else {
                    self.extConnection?.cancel()
                    self.extConnection = connection
                    self.receive(from: connection)
                }
                connection.start(queue: self.queue)
            }
        }
        listener.start(queue: queue)
    }

    private func receive(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 256 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                self.pcConnection?.send(content: data, completion: .contentProcessed { _ in })
            }
            if isComplete || error != nil {
                if connection === self.extConnection {
                    self.extConnection = nil
                }
                return
            }
            self.receive(from: connection)
        }
    }
}
