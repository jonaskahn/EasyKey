import AppKit

/// Titlebar-docked "keep on top" pin, shared by the clipboard and translation panels.
/// Lives at the titlebar's trailing edge, opposite the system close button.
final class KeepOnTopTitlebarAccessory: NSTitlebarAccessoryViewController {
    private let button = NSButton()
    private let titleForState: (Bool) -> String
    var onToggle: ((Bool) -> Void)?

    var isOn: Bool {
        didSet { refresh() }
    }

    init(isOn: Bool, title: @escaping (Bool) -> String) {
        self.isOn = isOn
        titleForState = title
        super.init(nibName: nil, bundle: nil)
        layoutAttribute = .right
        configureButton()
        view = button
        refresh()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureButton() {
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.frame = NSRect(x: 0, y: 0, width: 24, height: 24)
        button.target = self
        button.action = #selector(toggle)
        button.setAccessibilityIdentifier("PanelKeepOnTopButton")
    }

    @objc
    private func toggle() {
        isOn.toggle()
        onToggle?(isOn)
    }

    private func refresh() {
        let symbolName = isOn ? "pin.fill" : "pin"
        let configuration = NSImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        button.contentTintColor = isOn ? .controlAccentColor : .secondaryLabelColor
        let label = titleForState(isOn)
        button.toolTip = label
        button.setAccessibilityLabel(label)
    }
}
