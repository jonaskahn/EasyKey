import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

DispatchQueue.main.async {
    let hostURL = Bundle.main.bundleURL
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let hostBundleIdentifier = "one.ifelse.easykey"
    let hostIsRunning = NSRunningApplication.runningApplications(
        withBundleIdentifier: hostBundleIdentifier
    ).contains { $0.bundleURL == hostURL }

    guard !hostIsRunning else {
        NSApp.terminate(nil)
        return
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false
    configuration.hides = true
    NSWorkspace.shared.openApplication(at: hostURL, configuration: configuration) { _, _ in
        NSApp.terminate(nil)
    }
}

app.run()
