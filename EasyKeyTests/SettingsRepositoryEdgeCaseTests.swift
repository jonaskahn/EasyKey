@testable import EasyEngineCore
import XCTest

@MainActor
final class SettingsRepositoryEdgeCaseTests: XCTestCase {
    func testDefaultFileURL() {
        let url = SettingsRepository.defaultFileURL
        XCTAssertTrue(url.path.contains("EasyKey"))
        XCTAssertEqual(url.lastPathComponent, "settings.json")
        XCTAssertFalse(url.path.isEmpty)
    }

    func testImport_FileTooLarge_Throws() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let oversizedURL = directory.appendingPathComponent("huge.json")
        let oversized = Data(repeating: UInt8(ascii: "a"), count: SettingsRepository.maxImportFileBytes + 1)
        try oversized.write(to: oversizedURL)

        let repo = SettingsRepository(fileURL: directory.appendingPathComponent("dst.json"))
        XCTAssertThrowsError(try repo.import(from: oversizedURL)) { error in
            XCTAssertEqual(error as? SettingsRepositoryError, .importFileTooLarge)
        }
    }

    func testLoadWithInvalidJSON() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("invalid.json")
        try "not json".write(to: fileURL, atomically: true, encoding: .utf8)

        let repo = SettingsRepository(fileURL: fileURL)
        XCTAssertEqual(repo.settings, .defaults)
    }

    func testSaveCreatesFile() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("settings.json")
        let repo = SettingsRepository(fileURL: fileURL)
        repo.update { $0.input.inputMethod = .vni }
        await repo.saveNow()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testConfigurationSnapshotAllFields() {
        let repo = SettingsRepository(fileURL: nil)
        repo.update {
            $0.input.inputMethod = .vni
            $0.input.encoding = .tcvn3
            $0.typing.restoreInvalidWord = true
        }
        let snapshot = repo.configurationSnapshot
        XCTAssertEqual(snapshot.inputMethod, .vni)
        XCTAssertEqual(snapshot.outputEncoding, .tcvn3)
        XCTAssertTrue(snapshot.autoRestoreKeys)
    }

    func testDiagnosticEntries() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let sourceURL = directory.appendingPathComponent("src.json")
        let destRepo = SettingsRepository(fileURL: directory.appendingPathComponent("dst.json"))
        let srcRepo = SettingsRepository(fileURL: sourceURL)
        srcRepo.update { $0.input.inputMethod = .simpleTelex }
        await srcRepo.saveNow()

        let diagnostic = try destRepo.import(from: sourceURL)
        XCTAssertFalse(diagnostic.entries.isEmpty)
        XCTAssertEqual(destRepo.settings.input.inputMethod, .simpleTelex)
    }

    func testImportNonExistentFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let repo = SettingsRepository(fileURL: directory.appendingPathComponent("dst.json"))
        XCTAssertThrowsError(try repo.import(from: directory.appendingPathComponent("nonexistent.json")))
    }

    func testExportToFile() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let repo = SettingsRepository(fileURL: directory.appendingPathComponent("src.json"))
        repo.update { $0.input.inputMethod = .vni }
        await repo.saveNow()

        let exportURL = directory.appendingPathComponent("export.json")
        try repo.export(to: exportURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
    }

    func testRequestSaveThrottling() {
        let repo = SettingsRepository(fileURL: nil)
        repo.update { $0.input.inputMethod = .vni }
        repo.update { $0.input.inputMethod = .simpleTelex }

        XCTAssertEqual(repo.settings.input.inputMethod, .simpleTelex)
    }
}
