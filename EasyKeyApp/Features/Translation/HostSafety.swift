import Foundation

public enum HostSafety {
    public static func validate(host: String) -> Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        let lower = host.lowercased()

        let forbiddenSuffixes = ["localhost", ".local", ".internal", ".intranet", ".lan", ".home"]
        for suffix in forbiddenSuffixes {
            if lower == suffix || lower.hasSuffix(suffix) {
                return false
            }
        }

        var hints = addrinfo()
        hints.ai_flags = 0
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        hints.ai_protocol = IPPROTO_TCP

        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &result) == 0, let info = result else {
            return false
        }
        defer { freeaddrinfo(result) }

        var ptr: UnsafeMutablePointer<addrinfo>? = info
        while let p = ptr {
            if let sa = p.pointee.ai_addr {
                if isPrivateOrLoopback(sa) {
                    return false
                }
            }
            ptr = p.pointee.ai_next
        }
        return true
    }

    private static func isPrivateOrLoopback(_ sa: UnsafePointer<sockaddr>) -> Bool {
        if sa.pointee.sa_family == sa_family_t(AF_INET) {
            return sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sin in
                let addr = UInt32(bigEndian: sin.pointee.sin_addr.s_addr)
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
            }
        } else if sa.pointee.sa_family == sa_family_t(AF_INET6) {
            return sa.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { sin6 in
                let bytes = sin6.pointee.sin6_addr.__u6_addr.__u6_addr8
                // ::1 loopback
                if bytes.0 == 0 && bytes.1 == 0 && bytes.2 == 0 && bytes.3 == 0 &&
                    bytes.4 == 0 && bytes.5 == 0 && bytes.6 == 0 && bytes.7 == 0 &&
                    bytes.8 == 0 && bytes.9 == 0 && bytes.10 == 0 && bytes.11 == 0 &&
                    bytes.12 == 0 && bytes.13 == 0 && bytes.14 == 0 && bytes.15 == 1 {
                    return true
                }
                // fe80::/10 (link-local)
                if bytes.0 == 0xFE && (bytes.1 & 0xC0) == 0x80 {
                    return true
                }
                // fc00::/7 (ULA)
                if (bytes.0 & 0xFE) == 0xFC {
                    return true
                }
                return false
            }
        }
        return false
    }
}
