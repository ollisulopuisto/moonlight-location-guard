import AppKit
import CoreGraphics

/// Detects when a streaming/gaming app is running fullscreen.
///
/// macOS has no public API for "is this app streaming?", so we use fullscreen
/// as a proxy: when Moonlight / Steam Link / Parsec has a window covering most
/// of a screen, treat it as streaming. Location Services can then be disabled.
enum StreamDetector {
    /// Known streaming/gaming apps we can watch, with their bundle IDs and display names.
    static let knownTargets: [Target] = [
        Target(bundleID: "com.moonlight-stream.Moonlight", displayName: "Moonlight"),
        Target(bundleID: "com.valvesoftware.steamlink", displayName: "Steam Link"),
        Target(bundleID: "com.parsecgame.parsec", displayName: "Parsec"),
    ]

    /// A single detectable app target.
    struct Target: Identifiable, Hashable {
        var id: String { bundleID }
        let bundleID: String
        let displayName: String
    }

    /// Returns true if any of the given bundle IDs has a window covering >85% of a screen.
    ///
    /// - Parameter bundleIDs: Bundle IDs to check (filtered to enabled targets by the caller).
    /// - Returns: `true` when a matching app window is fullscreen.
    static func isStreamingFullscreen(for bundleIDs: [String]) -> Bool {
        guard !bundleIDs.isEmpty else { return false }

        let pids = Set(bundleIDs.flatMap {
            NSRunningApplication.runningApplications(withBundleIdentifier: $0).map(\.processIdentifier)
        })
        guard !pids.isEmpty else { return false }

        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] else { return false }

        let screens = NSScreen.screens.map(\.frame)
        var bestCover: Double = 0

        for w in list {
            guard let pid = w[kCGWindowOwnerPID as String] as? pid_t, pids.contains(pid),
                  let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = b["Width"], let height = b["Height"] else { continue }
            let winRect = CGRect(x: b["X"] ?? 0, y: b["Y"] ?? 0, width: width, height: height)
            let cover = screens.map { screen in
                let inter = winRect.intersection(screen)
                return max(inter.width, 0) * max(inter.height, 0) / (width * height)
            }.max() ?? 0
            if cover > bestCover { bestCover = cover }
        }

        return bestCover > 0.85
    }

    /// Returns the display name of the app currently streaming fullscreen, or nil.
    ///
    /// - Parameter bundleIDs: Bundle IDs to consider.
    /// - Returns: The `displayName` of the best-matching streaming app, or nil.
    static func streamingAppName(for bundleIDs: [String]) -> String? {
        let pids = Set(bundleIDs.flatMap {
            NSRunningApplication.runningApplications(withBundleIdentifier: $0).map(\.processIdentifier)
        })
        guard !pids.isEmpty else { return nil }

        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] else { return nil }

        let screens = NSScreen.screens.map(\.frame)
        var best: (cover: Double, name: String)?

        for target in knownTargets where bundleIDs.contains(target.bundleID) {
            for w in list {
                guard let pid = w[kCGWindowOwnerPID as String] as? pid_t, pids.contains(pid),
                      let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                      let width = b["Width"], let height = b["Height"] else { continue }
                let winRect = CGRect(x: b["X"] ?? 0, y: b["Y"] ?? 0, width: width, height: height)
                let cover = screens.map { screen in
                    let inter = winRect.intersection(screen)
                    return max(inter.width, 0) * max(inter.height, 0) / (width * height)
                }.max() ?? 0
                if cover > 0.85 && (best == nil || cover > best!.cover) {
                    best = (cover, target.displayName)
                }
            }
        }

        return best?.name
    }
}
