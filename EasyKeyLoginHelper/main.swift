import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Path-walk invariant: Bundle.main.bundleURL is 4 levels up from
// Contents/Library/LoginItems/EasyKeyLoginHelper.app
// .../EasyKey.app/Contents/Library/LoginItems/EasyKeyLoginHelper.app -> .../EasyKey.app
let hostURL = Bundle.main.bundleURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

// Verify launch-time code signing information if running in signed build
#if !DEBUG
var code: SecCode?
if SecCodeCopySelf([], &code) == errSecSuccess, let code = code {
    var staticCode: SecStaticCode?
    if SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode = staticCode {
        var info: CFDictionary?
        if SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
           let dict = info as? [String: Any],
           let team = dict[kSecCodeInfoTeamIdentifier as String] as? String {
            // Validate expected Team ID if non-empty
            if !team.isEmpty && team != "TEAMID12345" {
                NSApp.terminate(nil)
            }
        }
    }
}
#endif

// Validate host bundle URL: must end with .app and match bundle ID
guard hostURL.pathExtension == "app",
      Bundle(url: hostURL)?.bundleIdentifier == "one.ifelse.easykey" else {
    NSApp.terminate(nil)
    exit(0)
}

// 3s launch watchdog
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
    NSApp.terminate(nil)
}

DispatchQueue.main.async {
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
