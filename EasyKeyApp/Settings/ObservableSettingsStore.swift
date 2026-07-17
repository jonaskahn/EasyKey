import Combine
import EasyEngineCore
import Foundation

/// App-layer observable wrapper around the framework-free `SettingsRepository`.
@MainActor
final class ObservableSettingsStore: ObservableObject {
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

    var configurationSnapshot: EngineConfiguration {
        repository.configurationSnapshot
    }
}

typealias SettingsStore = ObservableSettingsStore
