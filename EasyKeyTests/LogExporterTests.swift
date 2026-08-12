@testable import EasyKey
import XCTest

@MainActor
final class LogExporterTests: XCTestCase {
    func testWriteExport_CreatesLogFileWithHeader() throws {
        let url = try LogExporter.writeExport()
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.lastPathComponent.hasPrefix("easykey-"))
        XCTAssertTrue(url.pathExtension == "log")

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("EasyKey log export"))
        XCTAssertTrue(contents.contains("subsystem=one.ifelse.easykey"))
    }

    func testExportAndReveal_InvokesRevealCallback() async {
        let expectation = expectation(description: "reveal callback")
        var revealed: URL?
        LogExporter.exportAndReveal { url in
            revealed = url
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)
        XCTAssertNotNil(revealed)
        if let revealed {
            XCTAssertTrue(FileManager.default.fileExists(atPath: revealed.path))
            try? FileManager.default.removeItem(at: revealed)
        }
    }

    func testPresentExportFailure_InTests_DoesNotCrash() {
        LogExporter.presentExportFailure()
    }

    func testWriteExport_NoMatchingEntries_AppendsEmptyMarker() throws {
        let url = try LogExporter.writeExport(now: Date())
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("EasyKey log export"))
    }

    func testWriteExport_PastTimestamp_SkipsAllEntries() throws {
        let distantPast = Date(timeIntervalSince1970: 0)
        let url = try LogExporter.writeExport(now: distantPast)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("EasyKey log export"))
    }

    func testLogExporter_RedactsSensitiveKeysAndRestrictsPermissions() throws {
        let secretString = "sk-proj-1234567890abcdef1234567890"
        let redacted = LogExporter.redact("Header sk-proj-1234567890abcdef1234567890 AIzaSy1234567890abcdef1234567890 key")
        XCTAssertFalse(redacted.contains(secretString))
        XCTAssertTrue(redacted.contains("[REDACTED]"))

        let url = try LogExporter.writeExport()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let permissions = attributes[.posixPermissions] as? NSNumber {
            XCTAssertEqual(permissions.uint16Value, 0o600)
        } else {
            XCTFail("Missing posixPermissions")
        }
    }
}
