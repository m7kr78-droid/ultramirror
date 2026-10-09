import Network
import UIKit

enum DNSChoice: String, CaseIterable, Identifiable {
    case cloudflare
    case google
    case quad9

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cloudflare: return "Cloudflare"
        case .google: return "Google"
        case .quad9: return "Quad9"
        }
    }

    var serverURL: String {
        switch self {
        case .cloudflare: return "https://cloudflare-dns.com/dns-query"
        case .google: return "https://dns.google/dns-query"
        case .quad9: return "https://dns.quad9.net/dns-query"
        }
    }
}

enum ConnectionTune {
    static func measure(host: String, completion: @escaping (Int?) -> Void) {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(nil)
            return
        }
        let started = Date()
        let connection = NWConnection(host: NWEndpoint.Host(trimmed), port: 443, using: .tcp)
        let queue = DispatchQueue(label: "ping")
        var finished = false
        connection.stateUpdateHandler = { state in
            guard !finished else { return }
            switch state {
            case .ready:
                finished = true
                let ms = Int(Date().timeIntervalSince(started) * 1000)
                connection.cancel()
                DispatchQueue.main.async { completion(ms) }
            case .failed, .cancelled:
                finished = true
                connection.cancel()
                DispatchQueue.main.async { completion(nil) }
            default:
                break
            }
        }
        connection.start(queue: queue)
        queue.asyncAfter(deadline: .now() + 5) {
            guard !finished else { return }
            finished = true
            connection.cancel()
            DispatchQueue.main.async { completion(nil) }
        }
    }

    static func installDNS(_ choice: DNSChoice) {
        let body = profile(choice).data(using: .utf8) ?? Data()
        ProfileServer.shared.serve(body) { url in
            guard let url else { return }
            UIApplication.shared.open(url)
        }
    }

    private static func profile(_ choice: DNSChoice) -> String {
        let inner = UUID().uuidString
        let outer = UUID().uuidString
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
        <key>PayloadContent</key><array><dict>
        <key>DNSSettings</key><dict>
        <key>DNSProtocol</key><string>HTTPS</string>
        <key>ServerURL</key><string>\(choice.serverURL)</string>
        </dict>
        <key>PayloadDisplayName</key><string>by sonic \(choice.title)</string>
        <key>PayloadIdentifier</key><string>com.ultramirror.app.dns.\(choice.rawValue)</string>
        <key>PayloadType</key><string>com.apple.dnsSettings.managed</string>
        <key>PayloadUUID</key><string>\(inner)</string>
        <key>PayloadVersion</key><integer>1</integer>
        </dict></array>
        <key>PayloadDisplayName</key><string>by sonic \(choice.title)</string>
        <key>PayloadIdentifier</key><string>com.ultramirror.app.dns</string>
        <key>PayloadType</key><string>Configuration</string>
        <key>PayloadUUID</key><string>\(outer)</string>
        <key>PayloadVersion</key><integer>1</integer>
        </dict></plist>
        """
    }
}

final class ProfileServer {
    static let shared = ProfileServer()
    private var listener: NWListener?
    private let port: UInt16 = 8941

    func serve(_ body: Data, completion: @escaping (URL?) -> Void) {
        listener?.cancel()
        guard let listener = try? NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!) else {
            completion(nil)
            return
        }
        listener.newConnectionHandler = { connection in
            connection.start(queue: .global())
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { _, _, _, _ in
                let header = """
                HTTP/1.1 200 OK\r
                Content-Type: application/x-apple-aspen-config\r
                Content-Length: \(body.count)\r
                Connection: close\r
                \r

                """
                var response = Data(header.utf8)
                response.append(body)
                connection.send(content: response, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        }
        listener.start(queue: .global())
        self.listener = listener
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            completion(URL(string: "http://127.0.0.1:\(self.port)/dns.mobileconfig"))
        }
    }
}
