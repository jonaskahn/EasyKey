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

    // MARK: - Helpers

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
}
