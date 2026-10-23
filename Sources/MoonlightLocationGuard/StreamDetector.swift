import AppKit
import CoreGraphics

/// Detects when Moonlight is streaming fullscreen.
///
/// We can't hook Moonlight directly, so we treat a fullscreen Moonlight window
/// as "streaming". Several bundle IDs are tried because the App Store and
/// direct-download builds may differ, and the fullscreen check is lenient
/// (window covers most of the screen) rather than pixel-exact.
enum StreamDetector {
    static let bundleIDs = [
        "com.moonlight-stream.Moonlight",
        "com.moonlight.Moonlight",
        "com.moonlightstream.Moonlight",
    ]

    static func isStreamingFullscreen() -> Bool {
        var candidates: [NSRunningApplication] = []
        for bid in bundleIDs {
            candidates.append(contentsOf: NSRunningApplication.runningApplications(withBundleIdentifier: bid))
        }
        let pids = Set(candidates.map(\.processIdentifier))

        guard !pids.isEmpty else {
            return false
        }

        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] else {
            return false
        }

        let screens = NSScreen.screens.map(\.frame)
        var best: (pid: pid_t, cover: Double)?
        var moonWindows = 0

        for w in list {
            guard let pid = w[kCGWindowOwnerPID as String] as? pid_t, pids.contains(pid) else { continue }
            moonWindows += 1
            guard let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = b["Width"], let height = b["Height"] else { continue }
            let winRect = CGRect(x: b["X"] ?? 0, y: b["Y"] ?? 0, width: width, height: height)

            // How much of this window is covered by any single screen?
            let cover = screens.map { screen in
                let inter = winRect.intersection(screen)
                let interArea = max(inter.width, 0) * max(inter.height, 0)
                return interArea / (width * height)
            }.max() ?? 0

            if best == nil || cover > best!.cover { best = (pid, cover) }
        }

        // Consider it streaming if a Moonlight window covers most of a screen.
        return best.map { $0.cover > 0.85 } ?? false
    }
}
