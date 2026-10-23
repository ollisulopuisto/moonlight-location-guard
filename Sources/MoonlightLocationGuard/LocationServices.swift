import Foundation

/// Toggles macOS Location Services through a root-owned helper that
/// `install-helper.sh` whitelists in sudoers (passwordless, that one command only).
enum LocationServices {
    static let helper = "/usr/local/libexec/mlg-location"

    static var helperInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: helper)
    }

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

    /// nil when the state cannot be read.
    static func isEnabled() -> Bool? {
        let r = run("status")
        guard r.ok else { return nil }
        return r.output == "1"
    }
}
