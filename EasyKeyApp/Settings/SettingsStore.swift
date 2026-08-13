import Combine
import EasyEngineCore
import Foundation
import SwiftUI

/// App-layer observable wrapper around the framework-free `SettingsRepository`.
@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: EasyKeySettings

    private let repository: SettingsRepository

    init(fileURL: URL? = nil) {
        let repository = SettingsRepository(fileURL: fileURL)
        self.repository = repository
        settings = repository.settings
        repository.onSettingsChange = { [weak self] settings in
            self?.settings = settings
        }
    }

    static var defaultFileURL: URL {
        SettingsRepository.defaultFileURL
    }

    func update(_ transform: (inout EasyKeySettings) -> Void) {
        repository.update(transform)
    }

    func binding<T>(_ keyPath: WritableKeyPath<EasyKeySettings, T>) -> Binding<T> {
        Binding(
            get: { [weak self] in
                self?.settings[keyPath: keyPath] ?? EasyKeySettings.defaults[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                self?.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    func reset() {
        repository.reset()
    }

    func export(to url: URL) throws {
        try repository.export(to: url)
    }

    func `import`(from url: URL) throws -> ImportDiagnostics {
        try repository.import(from: url)
    }

    func load() {
        repository.load()
    }

    func saveNow() async {
        await repository.saveNow()
    }
}
