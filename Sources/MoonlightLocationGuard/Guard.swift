import Foundation
import SwiftUI

/// Central state machine for Moonlight Location Guard.
///
/// Responsibilities:
/// - Holds the master on/off switch and per-app streaming target toggles (persisted via UserDefaults).
/// - Polls every 2 seconds to detect whether any enabled app is running fullscreen (streaming).
/// - Turns Location Services off when streaming starts, and back on when it stops.
/// - Remembers (via `weDisabled`) that it took over Location Services so it can restore them
///   on quit or crash, even across relaunches.
/// - Emits published properties that drive the SwiftUI menu bar window and icon.
@MainActor
final class Guard: ObservableObject {
    /// Master switch for the whole feature. When false, nothing is toggled.
    @AppStorage("guardEnabled") var enabled = true

    /// Comma-separated bundle IDs of apps the user has opted in to watch.
    /// Defaults to all known targets (Moonlight, Steam Link, Parsec).
    @AppStorage("streamTargetsEnabled") private var streamTargetsEnabledRaw = {
        StreamDetector.knownTargets.map(\.bundleID).joined(separator: ",")
    }()

    /// Persisted so a crash while Location Services were disabled is repaired on next launch.
    @AppStorage("weDisabled") private var weDisabled = false

    /// Whether Moonlight/Steam Link/Parsec is currently streaming fullscreen.
    @Published var streaming = false
    /// Display name of the app currently streaming, if any.
    @Published var streamingApp: String?
    /// Human-readable status shown in the menu window.
    @Published var status = "Idle"
    /// Timestamped debug log of every on/off event (and failures).
    @Published var logEntries: [LogEntry] = []
    /// Published so the per-app toggle row refreshes when a switch is flipped.
    @Published private(set) var targetEnabledState: [String: Bool] = [:]

    private var timer: Timer?

    /// Bundle IDs the user has enabled for detection.
    var enabledBundleIDs: Set<String> {
        Set(streamTargetsEnabledRaw
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) })
    }

    /// The user-facing targets, with whether each is enabled.
    var targets: [StreamDetector.Target] {
        StreamDetector.knownTargets.map { target in
            StreamDetector.Target(
                bundleID: target.bundleID,
                displayName: target.displayName
            )
        }
    }

    /// Whether a given target's bundle ID is currently enabled for detection.
    func isTargetEnabled(_ bundleID: String) -> Bool {
        enabledBundleIDs.contains(bundleID)
    }

    /// Enable or disable detection for a given bundle ID and persist the change.
    func setTargetEnabled(_ bundleID: String, enabled: Bool) {
        var current = enabledBundleIDs
        if enabled { current.insert(bundleID) } else { current.remove(bundleID) }
        streamTargetsEnabledRaw = current.sorted().joined(separator: ",")
        refreshTargetStates()
    }

    private func refreshTargetStates() {
        targetEnabledState = Dictionary(uniqueKeysWithValues:
            StreamDetector.knownTargets.map { ($0.bundleID, isTargetEnabled($0.bundleID)) })
    }

    init() {
        refreshTargetStates()
        if !LocationServices.helperInstalled {
            status = "Helper not installed — run install-helper.sh"
        } else if weDisabled {
            restore()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.restore() } }
    }

    /// Menu bar icon image: red filled shield when active, blue outline when inactive.
    var iconImage: NSImage { weDisabled ? AppIcon.active : AppIcon.inactive }

    /// Called every 2 seconds by the polling timer.
    func tick() {
        let activeIDs = Array(enabledBundleIDs)
        let now = StreamDetector.isStreamingFullscreen(for: activeIDs)
        let appName = now ? StreamDetector.streamingAppName(for: activeIDs) : nil
        defer {
            streaming = now
            streamingApp = appName
        }
        guard LocationServices.helperInstalled else { return }

        if enabled && now && !weDisabled {
            // Only take over if Location Services was on; otherwise leave it alone.
            guard LocationServices.isEnabled() == true else {
                status = "Already off"
                return
            }
            let r = LocationServices.run("off")
            if r.ok {
                weDisabled = true
                status = "Location Services off (\(streamingApp ?? "streaming"))"
                log("Location Services OFF (\(streamingApp ?? "streaming"))")
            } else {
                status = "Failed: \(r.output)"
                log("Failed to turn Location Services off: \(r.output)")
            }
        } else if weDisabled && (!now || !enabled) {
            restore()
        } else if now {
            status = "Location Services off (\(streamingApp ?? "streaming"))"
        } else {
            status = "Idle"
        }
    }

    /// Re-enable Location Services and clear the `weDisabled` flag.
    func restore() {
        guard weDisabled else { return }
        let r = LocationServices.run("on")
        if r.ok {
            weDisabled = false
            status = "Location Services restored"
            log("Location Services ON")
        } else {
            status = "Restore failed: \(r.output)"
            log("Failed to restore Location Services: \(r.output)")
        }
    }

    /// Human-readable "last toggled" date/time string, or "Never".
    var lastToggledString: String {
        guard let last = logEntries.first(where: { $0.message.contains("Location Services") }) else {
            return "Never"
        }
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .short
        return f.string(from: last.date)
    }

    /// Prepend a timestamped entry to the in-memory debug log (capped at 200).
    private func log(_ message: String) {
        let entry = LogEntry(date: Date(), message: message)
        logEntries.insert(entry, at: 0)
        if logEntries.count > 200 { logEntries.removeLast() }
    }
}

/// Debug-log entry with a timestamp.
struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let message: String

    var timestamp: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .short
        return f.string(from: date)
    }
}
