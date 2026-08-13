import Foundation

struct ResolvedHostAddress: Sendable, Equatable {
    enum Family: Sendable, Equatable {
        case ipv4
        case ipv6
    }

    let family: Family
    let bytes: [UInt8]

    var isPrivateOrLoopback: Bool {
        switch family {
        case .ipv4:
            guard bytes.count == 4 else { return false }
            let addr = UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
            // 127.0.0.0/8
            if (addr & 0xFF00_0000) == 0x7F00_0000 {
                return true
            }
            // 10.0.0.0/8
            if (addr & 0xFF00_0000) == 0x0A00_0000 {
                return true
            }
            // 172.16.0.0/12
            if (addr & 0xFFF0_0000) == 0xAC10_0000 {
                return true
            }
            // 192.168.0.0/16
            if (addr & 0xFFFF_0000) == 0xC0A8_0000 {
                return true
            }
            // 169.254.0.0/16 (link-local)
            if (addr & 0xFFFF_0000) == 0xA9FE_0000 {
                return true
            }
            // 100.64.0.0/10 (CGNAT)
            if (addr & 0xFFC0_0000) == 0x6440_0000 {
                return true
            }
            // 0.0.0.0/8 or 224.0.0.0/4
            if (addr & 0xFF00_0000) == 0x0000_0000 || (addr & 0xF000_0000) == 0xE000_0000 {
                return true
            }
            return false
        case .ipv6:
            guard bytes.count == 16 else { return false }
            // ::1 loopback
            if bytes[0 ... 14].allSatisfy({ $0 == 0 }), bytes[15] == 1 {
                return true
            }
            // fe80::/10 (link-local)
            if bytes[0] == 0xFE, (bytes[1] & 0xC0) == 0x80 {
                return true
            }
            // fc00::/7 (ULA)
            if (bytes[0] & 0xFE) == 0xFC {
                return true
            }
            return false
        }
    }
}

/// Resolves a host to its IP addresses. Injectable so tests never touch DNS.
struct HostResolver: Sendable {
    let resolve: @Sendable (String) -> [ResolvedHostAddress]

    static let system = HostResolver { host in
        var hints = addrinfo()
        hints.ai_flags = 0
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        hints.ai_protocol = IPPROTO_TCP

        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &result) == 0, let info = result else {
            return []
        }
        defer { freeaddrinfo(result) }

        var addresses: [ResolvedHostAddress] = []
        var ptr: UnsafeMutablePointer<addrinfo>? = info
        while let p = ptr {
            if let sa = p.pointee.ai_addr {
                if sa.pointee.sa_family == sa_family_t(AF_INET) {
                    let bytes = sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sin in
                        withUnsafeBytes(of: sin.pointee.sin_addr.s_addr) { Array($0) }
                    }
                    addresses.append(ResolvedHostAddress(family: .ipv4, bytes: bytes))
                } else if sa.pointee.sa_family == sa_family_t(AF_INET6) {
                    let bytes = sa.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { sin6 in
                        let addr = sin6.pointee.sin6_addr.__u6_addr.__u6_addr8
                        return [
                            addr.0, addr.1, addr.2, addr.3, addr.4, addr.5, addr.6, addr.7,
                            addr.8, addr.9, addr.10, addr.11, addr.12, addr.13, addr.14, addr.15,
                        ]
                    }
                    addresses.append(ResolvedHostAddress(family: .ipv6, bytes: bytes))
                }
            }
            ptr = p.pointee.ai_next
        }
        return addresses
    }
}

/// SSRF guard for translation endpoints. Rejects reserved suffixes, private
/// ranges, loopback, and hosts that fail to resolve.
enum HostSafety {
    private static let forbiddenSuffixes = ["localhost", ".local", ".internal", ".intranet", ".lan", ".home"]

    static func validate(host: String, resolver: HostResolver = .system) -> Bool {
        let lower = host.lowercased()
        for suffix in forbiddenSuffixes {
            if lower == suffix || lower.hasSuffix(suffix) {
                return false
            }
        }
        let addresses = resolver.resolve(lower)
        guard !addresses.isEmpty else { return false }
        return addresses.allSatisfy { !$0.isPrivateOrLoopback }
    }
}
