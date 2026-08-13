@testable import EasyKey
import XCTest

@MainActor
final class UpdateServiceTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("UpdateServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private func makeBundle(feedURL: String?, publicKey: String?) throws -> Bundle {
        let bundleURL = tempDirectory.appendingPathComponent("Fake-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(
            at: bundleURL.appendingPathComponent("Contents"),
            withIntermediateDirectories: true
        )
        var info: [String: Any] = [
            "CFBundleIdentifier": "one.ifelse.easykey.tests.fake",
            "CFBundleName": "Fake",
        ]
        if let feedURL {
            info["SUFeedURL"] = feedURL
        }
        if let publicKey {
            info["SUPublicEDKey"] = publicKey
        }
        let plistURL = bundleURL.appendingPathComponent("Contents/Info.plist")
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: plistURL)
        return try XCTUnwrap(Bundle(url: bundleURL))
    }

    func testIsConfigured_MissingFeedURL_IsFalse() throws {
        let bundle = try makeBundle(feedURL: nil, publicKey: "somekey")
        let service = UpdateService(bundle: bundle)
        XCTAssertFalse(service.isConfigured)
    }

    func testIsConfigured_UnresolvedBuildVariable_IsFalse() throws {
        let bundle = try makeBundle(feedURL: "$(SPARKLE_FEED_URL)", publicKey: "$(SPARKLE_PUBLIC_ED_KEY)")
        let service = UpdateService(bundle: bundle)
        XCTAssertFalse(service.isConfigured)
    }

    func testIsConfigured_NonHTTPSFeedURL_IsFalse() throws {
        let bundle = try makeBundle(feedURL: "http://example.com/appcast.xml", publicKey: "key")
        let service = UpdateService(bundle: bundle)
        XCTAssertFalse(service.isConfigured)
    }

    func testIsConfigured_ValidReleaseConfiguration_IsTrue() throws {
        let bundle = try makeBundle(feedURL: "https://example.com/appcast.xml", publicKey: "a-real-key")
        let service = UpdateService(bundle: bundle)
        XCTAssertTrue(service.isConfigured)
    }

    func testValidConfiguration_InTestMode_ReportsConfiguredWithoutLiveUpdater() throws {
        let bundle = try makeBundle(feedURL: "https://example.com/appcast.xml", publicKey: "a-real-key")
        let service = UpdateService(bundle: bundle)
        XCTAssertTrue(service.isConfigured)
        XCTAssertFalse(service.hasLiveUpdater, "Sparkle must never be instantiated in a test process")
    }

    func testValidConfiguration_OutsideTestMode_CreatesLiveUpdater() throws {
        let bundle = try makeBundle(feedURL: "https://example.com/appcast.xml", publicKey: "a-real-key")
        let service = UpdateService(bundle: bundle, isTesting: false)
        XCTAssertTrue(service.isConfigured)
        XCTAssertTrue(service.hasLiveUpdater)
    }

    func testStart_ConfiguredBundle_InTestMode_DoesNotStartLiveUpdater() throws {
        let bundle = try makeBundle(feedURL: "https://example.com/appcast.xml", publicKey: "a-real-key")
        let service = UpdateService(bundle: bundle)
        service.start()
        XCTAssertTrue(service.isConfigured)
        XCTAssertFalse(service.hasLiveUpdater)
    }

    func testCheckForUpdates_ConfiguredBundle_InTestMode_DoesNothing() throws {
        let bundle = try makeBundle(feedURL: "https://example.com/appcast.xml", publicKey: "a-real-key")
        let service = UpdateService(bundle: bundle)
        service.checkForUpdates()
        XCTAssertTrue(service.isConfigured)
        XCTAssertFalse(service.hasLiveUpdater)
    }

    func testStart_UnconfiguredService_DoesNotCrash() throws {
        let bundle = try makeBundle(feedURL: nil, publicKey: nil)
        let service = UpdateService(bundle: bundle)
        service.start()
    }

    func testCheckForUpdates_Unconfigured_DoesNotCrash() throws {
        let bundle = try makeBundle(feedURL: nil, publicKey: nil)
        let service = UpdateService(bundle: bundle)
        service.checkForUpdates()
    }
}
