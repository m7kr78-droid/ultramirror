import Foundation
import Network

final class USBStreamServer {
    private let port: UInt16
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.ultramirror.usb", qos: .userInteractive)
    private var pending = Data()
    private let maxPendingBytes = 1_000_000
    private var stopped = false

    init(port: UInt16) {
        self.port = port
    }

    func start() {
        queue.async { [weak self] in
            self?.stopped = false
            self?.connectLocked()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.stopped = true
            self?.connection?.cancel()
            self?.connection = nil
            self?.pending.removeAll(keepingCapacity: false)
        }
    }

    func send(annexB data: Data, isKey: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            guard let connection = self.connection, connection.state == .ready else {
                if isKey {
                    self.pending = data
                } else if self.pending.count < self.maxPendingBytes {
                    self.pending.append(data)
                }
                return
            }
            self.write(data, to: connection)
        }
    }

    private func connectLocked() {
        guard !stopped else { return }
        connection?.cancel()
        let parameters = NWParameters.tcp
        let tcp = parameters.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options
        tcp?.noDelay = true
        let connection = NWConnection(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!, using: parameters)
        self.connection = connection
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                if !self.pending.isEmpty {
                    self.write(self.pending, to: connection)
                    self.pending.removeAll(keepingCapacity: true)
                }
            case .failed, .cancelled:
                self.connection = nil
                if !self.stopped {
                    self.queue.asyncAfter(deadline: .now() + 0.4) {
                        self.connectLocked()
                    }
                }
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func write(_ data: Data, to connection: NWConnection) {
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if error != nil {
                self?.connection = nil
            }
        })
    }
}
