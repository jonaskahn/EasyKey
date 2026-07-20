import XCTest

/// Architecture fitness functions: enforce Clean Architecture Dependency Rule via source scan.
final class ArchitectureFitnessTests: XCTestCase {
    private var repoRoot: URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "EasyKeyTests" {
            url.deleteLastPathComponent()
            precondition(url.path != "/", "Could not locate EasyKeyTests from \(#filePath)")
        }
        return url.deletingLastPathComponent()
    }

    func testEasyEngineCore_DoesNotImportUIOrReactiveFrameworks() throws {
        let forbidden = ["AppKit", "SwiftUI", "Combine", "UIKit"]
        let violations = try importViolations(
            in: repoRoot.appendingPathComponent("EasyEngineCore"),
            forbiddenModules: forbidden
        )
        XCTAssertTrue(
            violations.isEmpty,
            "EasyEngineCore must stay Foundation-only. Violations:\n\(violations.joined(separator: "\n"))"
        )
    }

    func testEasyEngineCore_DoesNotImportAppOrKit() throws {
        let forbidden = ["EasyKey", "EasyKeyKit", "EasyKeyApp"]
        let violations = try importViolations(
            in: repoRoot.appendingPathComponent("EasyEngineCore"),
            forbiddenModules: forbidden
        )
        XCTAssertTrue(
            violations.isEmpty,
            "EasyEngineCore must not depend on App or Kit (prevents App↔Core cycles). Violations:\n\(violations.joined(separator: "\n"))"
        )
    }

    func testAppDoesNotCreateImportCycleIntoCore() throws {
        // Core must not reference App types; App may import Core one-way.
        let coreViolations = try importViolations(
            in: repoRoot.appendingPathComponent("EasyEngineCore"),
            forbiddenModules: ["EasyKey"]
        )
        let kitIntoApp = try importViolations(
            in: repoRoot.appendingPathComponent("EasyKeyKit"),
            forbiddenModules: ["EasyKey"]
        )
        XCTAssertTrue(
            coreViolations.isEmpty && kitIntoApp.isEmpty,
            "Dependency direction must be App → Kit → Core. Violations:\n\((coreViolations + kitIntoApp).joined(separator: "\n"))"
        )
    }

    func testTranslationLogsDoNotReferenceContentCredentialsOrRequestBodies() throws {
        let directory = repoRoot.appendingPathComponent("EasyKeyApp/Features/Translation")
        let sensitiveNames = ["sourceText", "translatedText", "apiKey", "credential", "prompt", "httpBody"]
        var violations: [String] = []
        for file in try swiftFiles(in: directory) {
            let source = try String(contentsOf: file, encoding: .utf8)
            for (index, line) in source.components(separatedBy: .newlines).enumerated()
                where line.contains("AppLog.") && sensitiveNames.contains(where: line.contains) {
                violations.append("\(file.lastPathComponent):\(index + 1): \(line)")
            }
        }
        XCTAssertTrue(
            violations.isEmpty,
            "Sensitive translation values must not reach logs or exports:\n\(violations.joined(separator: "\n"))"
        )
    }

    func testTranslationModelAndSettingsDoNotPersistContentOrSecrets() throws {
        var settingsSources = try swiftFiles(in: repoRoot.appendingPathComponent("EasyEngineCore/Settings"))
            .map { try String(contentsOf: $0, encoding: .utf8) }
            .joined(separator: "\n")
        settingsSources += try String(
            contentsOf: repoRoot.appendingPathComponent("EasyEngineCore/Translation/TranslationOptions.swift"),
            encoding: .utf8
        )
        for forbidden in ["sourceText", "translatedText", "translationHistory", "apiKey", "prompt"] {
            XCTAssertFalse(settingsSources.contains(forbidden), "Persisted settings contain forbidden translation field: \(forbidden)")
        }

        let model = try String(
            contentsOf: repoRoot.appendingPathComponent("EasyKeyApp/Features/Translation/TranslationModel.swift"),
            encoding: .utf8
        )
        XCTAssertFalse(model.contains("Codable"))
        XCTAssertFalse(model.contains("UserDefaults"))
        XCTAssertFalse(model.contains("FileManager"))
    }

    private func importViolations(in directory: URL, forbiddenModules: [String]) throws -> [String] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory.path) else {
            throw XCTSkip("Directory missing: \(directory.path)")
        }

        var violations: [String] = []
        let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        while let item = enumerator?.nextObject() as? URL {
            guard item.pathExtension == "swift" else { continue }
            let source = try String(contentsOf: item, encoding: .utf8)
            let relative = item.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
            for line in source.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("import ") else { continue }
                let module = String(trimmed.dropFirst("import ".count))
                    .trimmingCharacters(in: .whitespaces)
                    .split(separator: " ")
                    .first
                    .map(String.init) ?? ""
                if forbiddenModules.contains(module) {
                    violations.append("\(relative): \(trimmed)")
                }
            }
        }
        return violations
    }

    private func swiftFiles(in directory: URL) throws -> [URL] {
        let values = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        return values.filter { $0.pathExtension == "swift" }
    }
}
