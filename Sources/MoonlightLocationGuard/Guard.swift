import Foundation
import SwiftUI

@MainActor
final class Guard: ObservableObject {
    /// Master switch for the whole feature.
    @AppStorage("guardEnabled") var enabled = true

    /// Comma-separated bundle IDs of apps the user has opted in to watch.
    @AppStorage("streamTargetsEnabled") private var streamTargetsEnabledRaw = {
        StreamDetector.knownTargets.map(\.bundleID).joined(separator: ",")
    }()

    /// Persisted so a crash while disabled is repaired on next launch.
    @AppStorage("weDisabled") private var weDisabled = false

    @Published var streaming = false
    @Published var streamingApp: String?
    @Published var status = "Idle"
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

    func isTargetEnabled(_ bundleID: String) -> Bool {
        enabledBundleIDs.contains(bundleID)
    }

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

    var iconImage: NSImage { weDisabled ? AppIcon.active : AppIcon.inactive }

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

    var lastToggledString: String {
        // Derived from logEntries; last entry that toggled.
        guard let last = logEntries.first(where: { $0.message.contains("Location Services") }) else {
            return "Never"
        }
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .short
        return f.string(from: last.date)
    }

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
