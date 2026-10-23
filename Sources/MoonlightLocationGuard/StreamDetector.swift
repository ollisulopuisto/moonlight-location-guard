import AppKit
import CoreGraphics

/// Moonlight is categorised as a game, so macOS Game Mode engages when its window
/// is fullscreen. Game Mode has no public API; fullscreen Moonlight is the proxy.
enum StreamDetector {
    static let bundleID = "com.moonlight-stream.Moonlight"

    static func isStreamingFullscreen() -> Bool {
        let pids = Set(NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .map(\.processIdentifier))
        guard !pids.isEmpty,
              let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
                as? [[String: Any]] else { return false }
        let screens = NSScreen.screens.map(\.frame)
        for w in list {
            guard let pid = w[kCGWindowOwnerPID as String] as? pid_t, pids.contains(pid),
                  let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = b["Width"], let height = b["Height"] else { continue }
            if screens.contains(where: { abs($0.width - width) < 2 && abs($0.height - height) < 2 }) {
                return true
            }
        }
        return false
    }
}
