@testable import EasyKey
import XCTest

final class HostSafetyTests: XCTestCase {
    private func validate(_ host: String) -> Bool {
        HostSafety.validate(host: host)
    }

    func testValidate_ForbiddenSuffixes_AreRejected() {
        for host in [
            "localhost",
            "mysql.local",
            "api.internal",
            "backoffice.intranet",
            "nas.lan",
            "printer.home",
            "LOCALHOST",
            "A.LOCAL",
        ] {
            XCTAssertFalse(validate(host), "expected rejection for \(host)")
        }
    }

    func testValidate_PrivateIPv4Ranges_AreRejected() {
        for host in [
            "127.0.0.1",
            "127.255.255.254",
            "10.0.0.1",
            "10.255.255.255",
            "172.16.0.1",
            "172.31.255.254",
            "192.168.1.1",
            "192.168.254.254",
            "169.254.10.10",
            "100.64.0.1",
            "100.127.255.254",
            "0.0.0.0",
            "224.0.0.1",
        ] {
            XCTAssertFalse(validate(host), "expected rejection for \(host)")
        }
    }

    func testValidate_LoopbackIPv6_IsRejected() {
        XCTAssertFalse(validate("::1"))
    }

    func testValidate_LinkLocalAndULAIPv6_AreRejected() {
        for host in [
            "fe80::1",
            "fe80::abcd:ef",
            "fc00::1",
            "fd00::1",
            "fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
        ] {
            XCTAssertFalse(validate(host), "expected rejection for \(host)")
        }
    }

    func testValidate_PublicAddresses_AreAccepted() {
        for host in [
            "8.8.8.8",
            "1.1.1.1",
            "93.184.216.34",
            "2606:4700:4700::1111",
            "2001:4860:4860::8888",
        ] {
            XCTAssertTrue(validate(host), "expected acceptance for \(host)")
        }
    }

    func testValidate_UnresolvableHost_IsRejected() {
        XCTAssertFalse(validate("999.999.999.999"))
    }

    func testValidate_EdgeOfPrivateRanges_AreAccepted() {
        XCTAssertTrue(validate("172.32.0.1"))
        XCTAssertTrue(validate("100.128.0.1"))
    }

    func testValidate_InjectedResolverDrivesDecision() {
        let publicResolver = HostResolver { _ in
            [ResolvedHostAddress(family: .ipv4, bytes: [8, 8, 8, 8])]
        }
        let privateResolver = HostResolver { _ in
            [ResolvedHostAddress(family: .ipv4, bytes: [192, 168, 1, 1])]
        }
        XCTAssertTrue(HostSafety.validate(host: "unresolvable.example.com", resolver: publicResolver))
        XCTAssertFalse(HostSafety.validate(host: "unresolvable.example.com", resolver: privateResolver))
        XCTAssertFalse(HostSafety.validate(host: "anything.example.com", resolver: HostResolver { _ in [] }))
    }
}
