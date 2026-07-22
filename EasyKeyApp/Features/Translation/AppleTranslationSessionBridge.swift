import Foundation
import SwiftUI
import Translation

/// Narrow seam over `TranslationSession` delivery, so `AppleTranslationProvider`
/// can be tested without a live SwiftUI hierarchy or the system translation
/// daemon. `AppleTranslationSessionBridge` is the production implementation.
@available(macOS 15.0, *)
protocol AppleTranslationSessionBridging: Sendable {
    func translate(
        text: String,
        source: Locale.Language?,
        target: Locale.Language
    ) async throws -> TranslationSession.Response
}

/// Narrow seam over `LanguageAvailability`, so download-required and
/// unsupported-pair states are testable without the system translation daemon.
@available(macOS 15.0, *)
protocol AppleLanguageAvailabilityChecking: Sendable {
    func status(from source: Locale.Language, to target: Locale.Language?) async -> LanguageAvailability.Status
}

/// Wraps `LanguageAvailability` rather than retroactively conforming it to
/// `Sendable` (Apple does not mark it `Sendable`, and cross-module retroactive
/// `Sendable` conformance on someone else's class is unsound to declare
/// unconditionally). `LanguageAvailability`'s API surface is async-only
/// status queries with no shared mutable state, so `@unchecked Sendable`
/// here is safe.
@available(macOS 15.0, *)
struct SystemLanguageAvailability: AppleLanguageAvailabilityChecking, @unchecked Sendable {
    private let availability = LanguageAvailability()

    func status(from source: Locale.Language, to target: Locale.Language?) async -> LanguageAvailability.Status {
        await availability.status(from: source, to: target)
    }
}

/// Session cache keyed by configuration equality, plus configuration-keyed
/// waiters for sessions that have not arrived yet.
/// Generic and framework-agnostic (no `Translation` or `SwiftUI` reference)
/// specifically so this coordination logic — the part with real branching
/// behavior — is unit-testable without a live view hierarchy or a real
/// `TranslationSession`, which has no public constructor before macOS 26.
@MainActor
final class SessionSlot<Session: AnyObject, Configuration: Equatable> {
    private struct Waiter {
        let configuration: Configuration
        let continuation: CheckedContinuation<Session, Error>
    }

    private var activeSession: Session?
    private var activeConfiguration: Configuration?
    private var pendingWaiters: [UUID: Waiter] = [:]

    /// Invoked whenever the owner delivers a session for the configuration
    /// it most recently requested. Resolves any callers waiting on it, then
    /// keeps the session cached for direct reuse until `sleepWhileActive`
    /// returns (owner-driven: real callers pass `Task.sleep` bounded by
    /// SwiftUI cancelling the hosting task; tests pass a controllable stub).
    func attach(
        _ session: Session,
        configuration: Configuration,
        sleepWhileActive: () async -> Void = { try? await Task.sleep(nanoseconds: .max) }
    ) async {
        activeSession = session
        activeConfiguration = configuration
        let matchingWaiters = pendingWaiters.filter { $0.value.configuration == configuration }
        for (identifier, waiter) in matchingWaiters {
            pendingWaiters.removeValue(forKey: identifier)
            waiter.continuation.resume(returning: session)
        }
        await sleepWhileActive()
        if activeSession === session {
            activeSession = nil
            activeConfiguration = nil
        }
    }

    /// Returns the cached session if its configuration still matches;
    /// otherwise queues the caller and invokes `requestNewSession` so the
    /// owner can publish the new configuration (e.g. to a `@Published`
    /// property observed by `.translationTask`).
    func resolveSession(
        for requestedConfiguration: Configuration,
        requestNewSession: (Configuration) -> Void
    ) async throws -> Session {
        try Task.checkCancellation()
        if let activeSession, activeConfiguration == requestedConfiguration {
            return activeSession
        }
        let identifier = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                pendingWaiters[identifier] = Waiter(
                    configuration: requestedConfiguration,
                    continuation: continuation
                )
                requestNewSession(requestedConfiguration)
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancelWaiter(identifier)
            }
        }
    }

    private func cancelWaiter(_ identifier: UUID) {
        pendingWaiters.removeValue(forKey: identifier)?.continuation.resume(throwing: CancellationError())
    }
}

/// Bridges the SwiftUI-only `TranslationSession` lifecycle into an
/// async/await API `AppleTranslationProvider` can call directly. Apple ties
/// session creation to a live view via `.translationTask`; there is no
/// programmatic constructor before macOS 26. This type owns no translation
/// policy — it only publishes the configuration the hosting view observes
/// and resolves the session that view delivers back.
@available(macOS 15.0, *)
@MainActor
final class AppleTranslationSessionBridge: ObservableObject, AppleTranslationSessionBridging {
    @Published private(set) var configuration: TranslationSession.Configuration?

    private let slot = SessionSlot<TranslationSession, TranslationSession.Configuration>()

    /// Invoked by the hosting view's `.translationTask` action whenever the
    /// system delivers a session for the current configuration.
    func attach(_ session: TranslationSession, configuration: TranslationSession.Configuration) async {
        await slot.attach(session, configuration: configuration)
    }

    func translate(
        text: String,
        source: Locale.Language?,
        target: Locale.Language
    ) async throws -> TranslationSession.Response {
        let requestedConfiguration = TranslationSession.Configuration(source: source, target: target)
        let session = try await slot.resolveSession(for: requestedConfiguration) { [weak self] newConfiguration in
            self?.configuration = newConfiguration
        }
        return try await session.translate(text)
    }
}

/// Invisible view that keeps `AppleTranslationSessionBridge` supplied with a
/// live `TranslationSession`. The app composition embeds this once,
/// anywhere in the always-present window hierarchy, on macOS 15+.
@available(macOS 15.0, *)
struct AppleTranslationSessionHostView: View {
    @ObservedObject var bridge: AppleTranslationSessionBridge

    var body: some View {
        if let configuration = bridge.configuration {
            placeholder
                .translationTask(configuration) { session in
                    await bridge.attach(session, configuration: configuration)
                }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}
