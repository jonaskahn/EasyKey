@testable import EasyEngineCore
import XCTest

struct ConformanceFixture: Decodable {
    let inputMethod: String
    let encoding: String
    let keystrokes: [String]
    let expectedBuffer: String
    let description: String?

    var inputMethodEnum: InputMethod? {
        InputMethod(rawValue: inputMethod)
    }

    var encodingEnum: EncodingTable? {
        EncodingTable(rawValue: encoding)
    }
}

final class ConformanceFixtureTests: XCTestCase {
    func testAllFixturesConform() throws {
        let fixtures = try loadFixtures()
        try XCTSkipIf(fixtures.isEmpty, "No conformance fixtures found. Capture black-box data before beta.")

        var failures: [String] = []
        for (index, fixture) in fixtures.enumerated() {
            guard let inputMethod = fixture.inputMethodEnum else {
                failures.append("[\(index)] Unknown inputMethod: \(fixture.inputMethod)")
                continue
            }
            guard let encoding = fixture.encodingEnum else {
                failures.append("[\(index)] Unknown encoding: \(fixture.encoding)")
                continue
            }

            var engine = VietnameseEngine(
                configuration: EngineConfiguration(inputMethod: inputMethod, outputEncoding: encoding)
            )

            for keystroke in fixture.keystrokes {
                let event = try parseKeystroke(keystroke)
                _ = engine.process(event: event)
            }

            let actual = engine.currentBuffer
            if actual != fixture.expectedBuffer {
                let label = fixture.description ?? "fixture[\(index)]"
                failures.append("\(label): expected '\(fixture.expectedBuffer)', got '\(actual)'")
            }
        }

        XCTAssertTrue(failures.isEmpty, "Conformance failures:\n\(failures.joined(separator: "\n"))")
    }

    private func fixturesDirectory() throws -> URL {
        let testFile = URL(fileURLWithPath: #file)
        let projectRoot = testFile
            .deletingLastPathComponent() // EasyKeyTests/
            .deletingLastPathComponent() // apps/EasyKey/
        return projectRoot.appendingPathComponent("Fixtures", isDirectory: true)
    }

    private func loadFixtures() throws -> [ConformanceFixture] {
        let fixturesDir = try fixturesDirectory()
        guard FileManager.default.fileExists(atPath: fixturesDir.path) else {
            return []
        }
        let contents = try FileManager.default.contentsOfDirectory(
            at: fixturesDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        var allFixtures: [ConformanceFixture] = []
        for url in contents where url.pathExtension == "json" {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([ConformanceFixture].self, from: data)
            allFixtures.append(contentsOf: decoded)
        }
        return allFixtures
    }

    private func parseKeystroke(_ value: String) throws -> KeyEvent {
        switch value {
        case "space": return KeyEvent(kind: .space)
        case "backspace": return KeyEvent(kind: .backspace)
        case "return": return KeyEvent(kind: .return)
        case "tab": return KeyEvent(kind: .tab)
        case "escape": return KeyEvent(kind: .escape)
        case "leftArrow": return KeyEvent(kind: .leftArrow)
        case "rightArrow": return KeyEvent(kind: .rightArrow)
        case "upArrow": return KeyEvent(kind: .upArrow)
        case "downArrow": return KeyEvent(kind: .downArrow)
        default:
            guard let char = value.first, value.count == 1 else {
                XCTFail("Invalid keystroke value: '\(value)'")
                return .char("?")
            }
            return .char(char)
        }
    }
}
