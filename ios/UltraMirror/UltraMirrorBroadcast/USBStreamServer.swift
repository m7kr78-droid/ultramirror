import Foundation
import Network

final class USBStreamServer {
    private let port: UInt16
    private var listener: NWListener?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.ultramirror.usb", qos: .userInteractive)
    private var pending = Data()
    private let maxPendingBytes = 2_000_000

    init(port: UInt16) {
        self.port = port
    }

    func start() {
        queue.async { [weak self] in
            self?.startLocked()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.connection?.cancel()
            self?.connection = nil
            self?.listener?.cancel()
            self?.listener = nil
            self?.pending.removeAll(keepingCapacity: false)
        }
    }

    func send(annexB data: Data, isKey: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            guard let connection = self.connection else {
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

    private func startLocked() {
        listener?.cancel()
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.acceptLocalOnly = true
        let tcp = params.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options
        tcp?.noDelay = true
        tcp?.enableKeepalive = true
        tcp?.connectionTimeout = 2

        do {
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        } catch {
            return
        }

        listener?.newConnectionHandler = { [weak self] newConnection in
            guard let self else { return }
            self.queue.async {
                self.connection?.cancel()
                self.connection = newConnection
                newConnection.start(queue: self.queue)
                if !self.pending.isEmpty {
                    self.write(self.pending, to: newConnection)
                    self.pending.removeAll(keepingCapacity: true)
                }
                newConnection.stateUpdateHandler = { [weak self] state in
                    if case .failed = state {
                        self?.connection = nil
                    }
                    if case .cancelled = state {
                        self?.connection = nil
                    }
                }
            }
        }
        listener?.start(queue: queue)
    }

    private func write(_ data: Data, to connection: NWConnection) {
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if error != nil {
                self?.connection = nil
            }
        })
    }
}
