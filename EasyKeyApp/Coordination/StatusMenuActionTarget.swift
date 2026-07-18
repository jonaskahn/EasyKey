import AppKit
import EasyEngineCore

@MainActor
final class StatusMenuActionTarget: NSObject {
    weak var coordinator: AppCoordinator?

    @objc func selectVietnamese(_: Any?) {
        coordinator?.setLanguage(.vietnamese)
    }

    @objc func selectEnglish(_: Any?) {
        coordinator?.setLanguage(.english)
    }

    @objc func selectInputMethod(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let inputMethod = InputMethod(rawValue: rawValue)
        else { return }
        coordinator?.setInputMethod(inputMethod)
    }

    @objc func selectEncoding(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let encoding = EncodingTable(rawValue: rawValue)
        else { return }
        coordinator?.setEncoding(encoding)
    }

    @objc func toggleKeyboardPause(_: Any?) {
        coordinator?.keyboardService.togglePause()
    }

    @objc func restartKeyboardService(_: Any?) {
        coordinator?.restartKeyboardService()
    }

    @objc func convertClipboardAction(_: Any?) {
        coordinator?.convertClipboard()
    }

    @objc func clipboardHistoryAction(_: Any?) {
        coordinator?.showClipboardPanel()
    }

    @objc func openSettings(_: Any?) {
        coordinator?.showSettings()
    }

    @objc func openMacros(_: Any?) {
        coordinator?.showSettings(section: .macros)
    }

    @objc func showAbout(_: Any?) {
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(string: ""),
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showLogs(_: Any?) {
        coordinator?.showLogs()
    }

    @objc func quit(_: Any?) {
        NSApp.terminate(nil)
    }
}
