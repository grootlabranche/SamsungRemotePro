import Foundation
import Network
import Darwin
import Security

/// Local-network discovery using iOS Bonjour/mDNS browsing plus a bounded IPv4
/// subnet scan. Each candidate is verified against the Samsung /api/v2 endpoint.
final class SamsungDiscoveryService {
    private let queue = DispatchQueue(label: "fr.samsungremotepro.discovery")
    private let session: URLSession
    // Retain the delegate for the full lifetime of the URLSession.
    private let trustDelegate: SamsungLocalNetworkTrustDelegate

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 1.2
        configuration.timeoutIntervalForResource = 2
        let delegate = SamsungLocalNetworkTrustDelegate()
        trustDelegate = delegate
        session = URLSession(configuration: configuration,
                            delegate: delegate,
                            delegateQueue: nil)
    }

    func discover(timeout: TimeInterval = 2) async -> [SamsungTV] {
        // Bonjour/mDNS works through Apple's local-network stack without an app
        // multicast entitlement. Run it alongside a bounded IPv4 subnet fallback.
        async let bonjourTask = discoverHosts(timeout: timeout)
        let subnetHosts = localIPv4Hosts()
        async let subnetTask = probeCandidates(subnetHosts)
        let bonjourHosts = await bonjourTask
        let subnetTVs = await subnetTask
        let subnetSet = Set(subnetHosts)
        let extraBonjourHosts = bonjourHosts.filter { !subnetSet.contains($0) && isPrivateIPv4($0) }
        let bonjourTVs = await probeCandidates(extraBonjourHosts)
        var resultByHost: [String: SamsungTV] = [:]
        for tv in subnetTVs + bonjourTVs {
            if let existing = resultByHost[tv.host] {
                // Prefer the secure endpoint when both ports identify the same TV.
                if tv.usesSecureWebSocket && !existing.usesSecureWebSocket { resultByHost[tv.host] = tv }
            } else {
                resultByHost[tv.host] = tv
            }
        }
        return resultByHost.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func probe(host: String, useSecureConnection: Bool? = nil) async -> SamsungTV? {
        let normalized = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isPrivateIPv4(normalized) else { return nil }
        if let useSecureConnection {
            return await probe(host: normalized,
                               port: useSecureConnection ? AppConfiguration.defaultSecurePort : AppConfiguration.defaultInsecurePort,
                               secure: useSecureConnection)
        }
        // Probe both transports at once; prefer WSS if the TV answers on both.
        async let secure = probe(host: normalized, port: AppConfiguration.defaultSecurePort, secure: true)
        async let insecure = probe(host: normalized, port: AppConfiguration.defaultInsecurePort, secure: false)
        let (secureTV, insecureTV) = await (secure, insecure)
        return secureTV ?? insecureTV
    }

    private func probeCandidates(_ hosts: [String]) async -> [SamsungTV] {
        // Batch concurrency avoids opening hundreds of sockets simultaneously.
        var found: [SamsungTV] = []
        let orderedHosts = Array(Set(hosts)).sorted()
        for start in stride(from: 0, to: orderedHosts.count, by: 32) {
            let batch = Array(orderedHosts[start..<min(start + 32, orderedHosts.count)])
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
            let state = BonjourDiscoveryState(continuation: continuation)
            // Samsung TV service advertisements vary by model/year. Browse the
            // Smart View and Samsung remote service types; the API probe below
            // confirms whether a result is actually a controllable Samsung TV.
            for serviceType in ["_samsungmsf._tcp", "_samsungctl._tcp"] {
                let browser = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: .tcp)
                state.retain(browser)
                browser.browseResultsChangedHandler = { results, _ in
                    for result in results {
                        guard case .service = result.endpoint else { continue }
                        state.resolveHost(for: result.endpoint, on: self.queue)
                    }
                }
                browser.start(queue: queue)
            }
            queue.asyncAfter(deadline: .now() + max(0.8, timeout)) {
                state.finish()
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
            let hasSamsungIdentity = identity.contains("samsung") || name?.lowercased().contains("samsung") == true
            let hasSamsungDeviceSignature = !modelText.isEmpty &&
                (device["firmwareVersion"] as? String) != nil && (device["id"] as? String) != nil
            guard hasSamsungIdentity || hasSamsungDeviceSignature else { return nil }
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
            guard let namePointer = item.pointee.ifa_name,
                  String(cString: namePointer) == "en0",
                  let addressPointer = item.pointee.ifa_addr,
                  let netmaskPointer = item.pointee.ifa_netmask,
                  addressPointer.pointee.sa_family == UInt8(AF_INET),
                  netmaskPointer.pointee.sa_family == UInt8(AF_INET) else { continue }

            let address = addressPointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr }
            let netmask = netmaskPointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr }
            guard let ip = Self.dottedIPv4(from: address),
                  let maskString = Self.dottedIPv4(from: netmask),
                  let octets = Self.parseIPv4(ip),
                  let maskOctets = Self.parseIPv4(maskString),
                  isPrivateIPv4(ip) else { continue }

            let hostValue = Self.ipv4Integer(octets)
            let maskValue = Self.ipv4Integer(maskOctets)
            let networkValue = hostValue & maskValue
            let broadcastValue = networkValue | ~maskValue
            guard broadcastValue > networkValue, broadcastValue - networkValue > 1 else { continue }

            let firstHost = networkValue + 1
            let lastHost = broadcastValue - 1
            // Avoid an accidental scan of tens of thousands of devices on a wide
            // corporate subnet. For an unusually large subnet, scan a 1,024-address
            // window centered around the iPhone instead.
            let scanStart: UInt32
            let scanEnd: UInt32
            if lastHost - firstHost <= 1024 {
                scanStart = firstHost
                scanEnd = lastHost
            } else {
                scanStart = max(firstHost, hostValue > 512 ? hostValue - 512 : firstHost)
                scanEnd = min(lastHost, hostValue + 512)
            }
            guard scanStart <= scanEnd else { continue }
            for value in scanStart...scanEnd where value != hostValue {
                result.insert(Self.ipv4String(from: value))
            }
        }
        return Array(result).sorted()
    }

    private static func dottedIPv4(from address: in_addr_t) -> String? {
        var addressValue = address
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        return withUnsafePointer(to: &addressValue) { addressPointer -> String? in
            buffer.withUnsafeMutableBufferPointer { outputBuffer -> String? in
                guard let output = outputBuffer.baseAddress,
                      inet_ntop(AF_INET, addressPointer, output, socklen_t(INET_ADDRSTRLEN)) != nil else {
                    return nil
                }
                return String(cString: output)
            }
        }
    }

    private static func parseIPv4(_ host: String) -> [Int]? {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return nil }
        let octets = parts.compactMap { Int($0) }
        guard octets.count == 4, octets.allSatisfy({ (0...255).contains($0) }) else { return nil }
        return octets
    }

    private static func ipv4Integer(_ octets: [Int]) -> UInt32 {
        octets.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    private static func ipv4String(from value: UInt32) -> String {
        "\((value >> 24) & 255).\((value >> 16) & 255).\((value >> 8) & 255).\(value & 255)"
    }

    private func isPrivateIPv4(_ host: String) -> Bool {
        guard let p = Self.parseIPv4(host) else { return false }
        return p[0] == 10 || (p[0] == 192 && p[1] == 168) ||
            (p[0] == 172 && (16...31).contains(p[1])) ||
            (p[0] == 169 && p[1] == 254)
    }

}

private final class BonjourDiscoveryState: @unchecked Sendable {
    private let lock = NSLock()
    private let continuation: CheckedContinuation<[String], Never>
    private var hosts = Set<String>()
    private var endpointKeys = Set<String>()
    private var browsers: [NWBrowser] = []
    private var connections: [NWConnection] = []
    private var finished = false

    init(continuation: CheckedContinuation<[String], Never>) {
        self.continuation = continuation
    }

    func retain(_ browser: NWBrowser) {
        lock.lock()
        let shouldCancel = finished
        if !finished { browsers.append(browser) }
        lock.unlock()
        if shouldCancel { browser.cancel() }
    }

    func resolveHost(for endpoint: NWEndpoint, on queue: DispatchQueue) {
        let key = String(describing: endpoint)
        lock.lock()
        guard !finished, endpointKeys.insert(key).inserted else { lock.unlock(); return }
        let connection = NWConnection(to: endpoint, using: .tcp)
        connections.append(connection)
        lock.unlock()

        connection.stateUpdateHandler = { [weak self, weak connection] newState in
            guard let self, let connection else { return }
            switch newState {
            case .ready:
                if let remote = connection.currentPath?.remoteEndpoint,
                   case let .hostPort(host, _) = remote {
                    self.insert(String(describing: host))
                }
                connection.cancel()
            case .failed, .cancelled:
                break
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func insert(_ host: String) {
        lock.lock()
        if !finished { hosts.insert(host) }
        lock.unlock()
    }

    func finish() {
        lock.lock()
        guard !finished else { lock.unlock(); return }
        finished = true
        let result = Array(hosts)
        let browsersToCancel = browsers
        let connectionsToCancel = connections
        browsers.removeAll()
        connections.removeAll()
        lock.unlock()

        browsersToCancel.forEach { $0.cancel() }
        connectionsToCancel.forEach { $0.cancel() }
        continuation.resume(returning: result)
    }
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
