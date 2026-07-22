@testable import EasyKey
import XCTest

private final class FakeSession {
    let id: Int
    init(id: Int) {
        self.id = id
    }
}

private struct FakeConfiguration: Equatable {
    let value: String
}

@MainActor
final class SessionSlotTests: XCTestCase {
    func testResolveSession_WithNoActiveSession_QueuesAndRequestsNewSession() async throws {
        let slot = SessionSlot<FakeSession, FakeConfiguration>()
        var requested: [FakeConfiguration] = []

        let resolveTask = Task {
            try await slot.resolveSession(for: FakeConfiguration(value: "en-vi")) { config in
                requested.append(config)
            }
        }
        while requested.isEmpty {
            await Task.yield()
        }
        XCTAssertEqual(requested, [FakeConfiguration(value: "en-vi")])

        let session = FakeSession(id: 1)
        let attachTask = Task {
            await slot.attach(session, configuration: FakeConfiguration(value: "en-vi")) {}
        }

        let resolved = try await resolveTask.value
        XCTAssertIdentical(resolved, session)
        await attachTask.value
    }

    func testResolveSession_WithMatchingCachedConfiguration_ReturnsCachedSessionWithoutRequesting() async throws {
        let slot = SessionSlot<FakeSession, FakeConfiguration>()
        let session = FakeSession(id: 42)

        let attachTask = Task {
            await slot.attach(session, configuration: FakeConfiguration(value: "en-vi")) {
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
        await Task.yield()

        var requested = false
        let resolved = try await slot.resolveSession(for: FakeConfiguration(value: "en-vi")) { _ in
            requested = true
        }

        XCTAssertIdentical(resolved, session)
        XCTAssertFalse(requested, "A cache hit must not request a new session")
        await attachTask.value
    }

    func testResolveSession_WithDifferentConfigurationThanCached_RequestsNewSession() async throws {
        let slot = SessionSlot<FakeSession, FakeConfiguration>()
        let firstSession = FakeSession(id: 1)

        let firstAttach = Task {
            await slot.attach(firstSession, configuration: FakeConfiguration(value: "en-vi")) {
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
        await Task.yield()

        var requested: [FakeConfiguration] = []
        let resolveTask = Task {
            try await slot.resolveSession(for: FakeConfiguration(value: "vi-en")) { config in
                requested.append(config)
            }
        }
        while requested.isEmpty {
            await Task.yield()
        }
        XCTAssertEqual(requested, [FakeConfiguration(value: "vi-en")])

        let secondSession = FakeSession(id: 2)
        let secondAttach = Task {
            await slot.attach(secondSession, configuration: FakeConfiguration(value: "vi-en")) {}
        }

        let resolved = try await resolveTask.value
        XCTAssertIdentical(resolved, secondSession)
        await firstAttach.value
        await secondAttach.value
    }

    func testAttach_ResolvesMultiplePendingWaiters() async throws {
        let slot = SessionSlot<FakeSession, FakeConfiguration>()
        var firstRequested = false
        var secondRequested = false

        let firstResolve = Task {
            try await slot.resolveSession(for: FakeConfiguration(value: "en-vi")) { _ in firstRequested = true }
        }
        while !firstRequested {
            await Task.yield()
        }
        let secondResolve = Task {
            try await slot.resolveSession(for: FakeConfiguration(value: "en-vi")) { _ in secondRequested = true }
        }
        while !secondRequested {
            await Task.yield()
        }

        let session = FakeSession(id: 7)
        let attachTask = Task {
            await slot.attach(session, configuration: FakeConfiguration(value: "en-vi")) {}
        }

        let firstResolved = try await firstResolve.value
        let secondResolved = try await secondResolve.value
        XCTAssertIdentical(firstResolved, session)
        XCTAssertIdentical(secondResolved, session)
        await attachTask.value
    }

    func testAttach_ClearsActiveSessionAfterSleepCompletesWhenStillCurrent() async throws {
        let slot = SessionSlot<FakeSession, FakeConfiguration>()
        let session = FakeSession(id: 9)

        await slot.attach(session, configuration: FakeConfiguration(value: "en-vi")) {}

        var requested = false
        let resolveTask = Task {
            try await slot.resolveSession(for: FakeConfiguration(value: "en-vi")) { _ in requested = true }
        }
        while !requested {
            await Task.yield()
        }
        XCTAssertTrue(requested, "Cache must be cleared once the sleep-while-active window ends")

        let replacement = FakeSession(id: 10)
        await slot.attach(replacement, configuration: FakeConfiguration(value: "en-vi")) {}
        _ = try await resolveTask.value
    }

    func testAttach_WhenReplacedByNewerSessionBeforeSleepCompletes_DoesNotClearNewerSession() async throws {
        let slot = SessionSlot<FakeSession, FakeConfiguration>()
        let staleSession = FakeSession(id: 100)
        let freshSession = FakeSession(id: 200)

        let staleAttach = Task {
            await slot.attach(staleSession, configuration: FakeConfiguration(value: "en-vi")) {
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
        }
        await Task.yield()

        let freshAttach = Task {
            await slot.attach(freshSession, configuration: FakeConfiguration(value: "en-vi")) {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
        await Task.yield()

        await staleAttach.value

        var requested = false
        let resolveTask = Task {
            try await slot.resolveSession(for: FakeConfiguration(value: "en-vi")) { _ in requested = true }
        }
        try? await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertFalse(requested, "The stale attach's cleanup must not evict the newer session")
        let resolved = try await resolveTask.value
        XCTAssertIdentical(resolved, freshSession)

        await freshAttach.value
    }

    func testAttach_ResolvesOnlyWaitersForMatchingConfiguration() async throws {
        let slot = SessionSlot<FakeSession, FakeConfiguration>()
        var requests: [FakeConfiguration] = []
        let firstConfiguration = FakeConfiguration(value: "en-vi")
        let secondConfiguration = FakeConfiguration(value: "vi-en")

        let first = Task {
            try await slot.resolveSession(for: firstConfiguration) { requests.append($0) }
        }
        let second = Task {
            try await slot.resolveSession(for: secondConfiguration) { requests.append($0) }
        }
        while requests.count < 2 {
            await Task.yield()
        }

        let firstSession = FakeSession(id: 1)
        await slot.attach(firstSession, configuration: firstConfiguration) {}
        let firstResolved = try await first.value
        XCTAssertIdentical(firstResolved, firstSession)
        XCTAssertFalse(second.isCancelled)

        let secondSession = FakeSession(id: 2)
        await slot.attach(secondSession, configuration: secondConfiguration) {}
        let secondResolved = try await second.value
        XCTAssertIdentical(secondResolved, secondSession)
    }

    func testResolveSession_CancellationRemovesWaiter() async {
        let slot = SessionSlot<FakeSession, FakeConfiguration>()
        var requested = false
        let task = Task {
            try await slot.resolveSession(for: FakeConfiguration(value: "en-vi")) { _ in requested = true }
        }
        while !requested {
            await Task.yield()
        }

        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {} catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
