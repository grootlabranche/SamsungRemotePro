import Foundation
import Network
import Darwin
import Security

/// Local-network discovery inspired by the Samsung protocol handling used by
/// Home Assistant's SamsungTV Smart integration. That integration itself asks
/// for an IP; this iOS app adds an optional local-subnet fallback.
final class SamsungDiscoveryService {
    private let queue = DispatchQueue(label: "fr.samsungremotepro.ssdp")
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 1.2
        configuration.timeoutIntervalForResource = 2
        session = URLSession(configuration: configuration,
                            delegate: SamsungLocalNetworkTrustDelegate(),
                            delegateQueue: nil)
    }

    func discover(timeout: TimeInterval = 3) async -> [SamsungTV] {
        // SSDP multicast is not consistently available to third-party iOS apps.
        // Combine it with a bounded scan of the current Wi-Fi /24 when available.
        let ssdpHosts = await discoverHosts(timeout: timeout)
        let subnetHosts = localIPv4Hosts()
        let candidates = Array(Set(ssdpHosts + subnetHosts)).filter { isPrivateIPv4($0) }
        return await probeCandidates(candidates)
    }

    func probe(host: String, useSecureConnection: Bool? = nil) async -> SamsungTV? {
        let normalized = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        if let useSecureConnection {
            let secure = useSecureConnection
            return await probe(host: normalized,
                               port: secure ? AppConfiguration.defaultSecurePort : AppConfiguration.defaultInsecurePort,
                               secure: secure)
        }
        if let tv = await probe(host: normalized, port: AppConfiguration.defaultSecurePort, secure: true) { return tv }
        return await probe(host: normalized, port: AppConfiguration.defaultInsecurePort, secure: false)
    }

    private func probeCandidates(_ hosts: [String]) async -> [SamsungTV] {
        // Batch concurrency avoids opening hundreds of sockets simultaneously.
        var found: [SamsungTV] = []
        for start in stride(from: 0, to: hosts.count, by: 24) {
            let batch = Array(hosts[start..<min(start + 24, hosts.count)])
            let results = await withTaskGroup(of: SamsungTV?.self, returning: [SamsungTV].self) { group in
                for host in batch { group.addTask { await self.probe(host: host) } }
                var values: [SamsungTV] = []
                for await value in group { if let value { values.append(value) } }
                return values
            }
            found.append(contentsOf: results)
        }
        var seen = Set<String>()
        return found.filter { seen.insert($0.host).inserted }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func discoverHosts(timeout: TimeInterval) async -> [String] {
        await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.hostPort(host: "239.255.255.250", port: 1900)
            let connection = NWConnection(to: endpoint, using: .udp)
            let state = SSDPState()
            let request = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: ssdp:all\r\n\r\n"
            connection.stateUpdateHandler = { newState in
                guard case .ready = newState else { return }
                connection.send(content: Data(request.utf8), completion: .contentProcessed { _ in })
                func receive() {
                    connection.receiveMessage { data, _, _, error in
                        if error == nil, let data, let response = String(data: data, encoding: .utf8),
                           let host = Self.host(fromSSDPResponse: response) {
                            state.insert(host)
                        }
                        if error == nil { receive() }
                    }
                }
                receive()
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) {
                connection.cancel()
                continuation.resume(returning: state.values)
            }
        }
    }

    private func probe(host: String, port: Int, secure: Bool) async -> SamsungTV? {
        var components = URLComponents()
        components.scheme = secure ? "https" : "http"
        components.host = host
        components.port = port
        components.path = "/api/v2/"
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.2
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let device = root["device"] as? [String: Any] else { return nil }
            let model = (device["modelName"] as? String) ?? (device["model"] as? String)
            // Do not label an unverified endpoint as a Samsung TV.
            let manufacturer = (device["manufacturer"] as? String) ?? ""
            let deviceType = (device["type"] as? String) ?? ""
            let modelText = model ?? ""
            let identity = ([manufacturer, deviceType, modelText].joined(separator: " ")).lowercased()
            let name = (device["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard identity.contains("samsung") || modelText.lowercased().contains("q") || name?.lowercased().contains("samsung") == true else { return nil }
            // The /api/v2/ response itself is the identifying Samsung endpoint.
            // TokenAuthSupport describes pairing/token support, not whether the
            // WebSocket transport is TLS; keep the transport aligned with port.
            return SamsungTV(name: (name?.isEmpty == false ? name! : "Téléviseur Samsung"),
                             host: host, port: port, usesSecureWebSocket: secure,
                             model: model, lastSeen: .now)
        } catch { return nil }
    }

    private func localIPv4Hosts() -> [String] {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else { return [] }
        defer { freeifaddrs(interfaces) }
        var result = Set<String>()
        var current: UnsafeMutablePointer<ifaddrs>? = first
        while let item = current {
            defer { current = item.pointee.ifa_next }
            guard let addr = item.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET),
                  let name = item.pointee.ifa_name.map({ String(cString: $0) }), name == "en0" else { continue }
            let address = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr }
            var addressValue = address
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            let ip = withUnsafePointer(to: &addressValue) { addressPointer -> String? in
                guard inet_ntop(AF_INET, addressPointer, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else {
                    return nil
                }
                return String(cString: buffer)
            }
            guard let ip, isPrivateIPv4(ip), let octets = ip.split(separator: ".").compactMap({ Int($0) }), octets.count == 4 else { continue }
            // /24 is a practical fallback; skip own address and network/broadcast.
            for last in 1...254 where last != octets[3] { result.insert("\(octets[0]).\(octets[1]).\(octets[2]).\(last)") }
        }
        return Array(result)
    }

    private func isPrivateIPv4(_ host: String) -> Bool {
        let p = host.split(separator: ".").compactMap { Int($0) }
        guard p.count == 4, p.allSatisfy({ (0...255).contains($0) }) else { return false }
        return p[0] == 10 || (p[0] == 192 && p[1] == 168) || (p[0] == 172 && (16...31).contains(p[1])) || (p[0] == 169 && p[1] == 254)
    }

    private static func host(fromSSDPResponse response: String) -> String? {
        let headers = response.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let location = headers.first(where: { $0.lowercased().hasPrefix("location:") }) else { return nil }
        let value = String(location.dropFirst("LOCATION:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let host = URL(string: value)?.host else { return nil }
        return host
    }
}

private final class SSDPState: @unchecked Sendable {
    private let lock = NSLock()
    private var hosts = Set<String>()
    func insert(_ host: String) { lock.lock(); hosts.insert(host); lock.unlock() }
    var values: [String] { lock.lock(); defer { lock.unlock() }; return Array(hosts) }
}

/// Samsung TVs commonly use a self-signed certificate on their private LAN IP.
/// Accept that certificate only for RFC1918/link-local IPv4 endpoints, never public hosts.
final class SamsungLocalNetworkTrustDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              isPrivateAddress(challenge.protectionSpace.host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }

    private func isPrivateAddress(_ host: String) -> Bool {
        let p = host.split(separator: ".").compactMap { Int($0) }
        guard p.count == 4, p.allSatisfy({ (0...255).contains($0) }) else { return false }
        return p[0] == 10 || (p[0] == 192 && p[1] == 168) || (p[0] == 172 && (16...31).contains(p[1])) || (p[0] == 169 && p[1] == 254)
    }
}
