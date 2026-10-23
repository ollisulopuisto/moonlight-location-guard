import Foundation

/// Toggles macOS Location Services through a root-owned helper.
///
/// The helper (`/usr/local/libexec/mlg-location`) is installed once by
/// `install-helper.sh` and whitelisted in sudoers so this app can run it
/// passwordless via `sudo -n`. This enum wraps the `Process` calls.
enum LocationServices {
    /// Filesystem path to the root-owned helper installed by install-helper.sh.
    static let helper = "/usr/local/libexec/mlg-location"

    /// Whether the helper executable exists and is runnable.
    static var helperInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: helper)
    }

    /// Runs the helper with the given argument (`on`, `off`, or `status`).
    ///
    /// - Parameter arg: One of `"on"`, `"off"`, `"status"`.
    /// - Returns: A tuple `(ok: Bool, output: String)` indicating success and any output.
    @discardableResult
    static func run(_ arg: String) -> (ok: Bool, output: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", helper, arg]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return (false, error.localizedDescription) }
        p.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return (p.terminationStatus == 0, out)
    }

    /// Reads the current Location Services state.
    ///
    /// - Returns: `true` if enabled, `false` if disabled, `nil` if the state cannot be read.
    /// nil when the state cannot be read.
    static func isEnabled() -> Bool? {
        let r = run("status")
        guard r.ok else { return nil }
        return r.output == "1"
    }
}
