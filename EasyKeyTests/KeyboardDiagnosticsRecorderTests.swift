@testable import EasyKeyKit
import XCTest

final class KeyboardDiagnosticsRecorderTests: XCTestCase {
    func testSnapshotWhenEmpty() {
        let recorder = KeyboardDiagnosticsRecorder()
        XCTAssertTrue(recorder.snapshot.isEmpty)
    }

    func testSetEnabled() {
        let recorder = KeyboardDiagnosticsRecorder()
        recorder.setEnabled(true)
    }

    func testRecordWhenDisabled() {
        let recorder = KeyboardDiagnosticsRecorder()
        recorder.setEnabled(false)
        recorder.record(
            typeRawValue: 10,
            disposition: .passed,
            outputCount: 0,
            bundleIdentifier: nil,
            startedAt: 0
        )
        XCTAssertTrue(recorder.snapshot.isEmpty)
    }

    func testRecordWhenEnabled() {
        let recorder = KeyboardDiagnosticsRecorder()
        recorder.setEnabled(true)
        recorder.record(
            typeRawValue: 10,
            disposition: .passed,
            outputCount: 1,
            bundleIdentifier: "com.example.test",
            startedAt: 0
        )
        XCTAssertFalse(recorder.snapshot.isEmpty)
        let snapshot = recorder.snapshot
        XCTAssertEqual(snapshot.count, 1)
        XCTAssertEqual(snapshot[0].eventType, 10)
        XCTAssertEqual(snapshot[0].outputCount, 1)
        XCTAssertEqual(snapshot[0].bundleIdentifier, "com.example.test")
    }

    func testMedianCallbackLatencyEmpty() {
        let recorder = KeyboardDiagnosticsRecorder()
        XCTAssertNil(recorder.medianCallbackLatencyNanoseconds)
    }

    func testMedianCallbackLatencySingle() {
        let recorder = KeyboardDiagnosticsRecorder()
        recorder.setEnabled(true)
        recorder.record(
            typeRawValue: 10,
            disposition: .passed,
            outputCount: 0,
            bundleIdentifier: nil,
            startedAt: 0
        )
        XCTAssertNotNil(recorder.medianCallbackLatencyNanoseconds)
    }

    func testSetEnabledClearsData() {
        let recorder = KeyboardDiagnosticsRecorder()
        recorder.setEnabled(true)
        recorder.record(
            typeRawValue: 10,
            disposition: .passed,
            outputCount: 0,
            bundleIdentifier: nil,
            startedAt: 0
        )
        recorder.setEnabled(false)
        XCTAssertTrue(recorder.snapshot.isEmpty)
    }

    func testCapacityLimit() {
        let recorder = KeyboardDiagnosticsRecorder(capacity: 3)
        recorder.setEnabled(true)
        for i in 0 ..< 10 {
            recorder.record(
                typeRawValue: UInt32(i),
                disposition: .passed,
                outputCount: i,
                bundleIdentifier: nil,
                startedAt: 0
            )
        }
        let snapshot = recorder.snapshot
        XCTAssertEqual(snapshot.count, 3)
    }
}
