import Foundation
import SwiftUI

@MainActor
final class Guard: ObservableObject {
    @AppStorage("enabled") var enabled = true
    /// Persisted so a crash while disabled is repaired on next launch.
    @AppStorage("weDisabled") private var weDisabled = false
    @Published var streaming = false
    @Published var status = "Idle"
    @Published var showDebugLog = false
    @Published var logEntries: [LogEntry] = []
    private let df: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .medium
        return f
    }()
    private var timer: Timer?

    init() {
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
        let now = StreamDetector.isStreamingFullscreen()
        defer { streaming = now }
        guard LocationServices.helperInstalled else { return }
        if enabled && now && !weDisabled {
            // Only take over if Location Services was on; otherwise leave it alone.
            guard LocationServices.isEnabled() == true else { status = "Already off"; return }
            let r = LocationServices.run("off")
            if r.ok {
                weDisabled = true
                status = "Location Services off while streaming"
                log("Location Services OFF (streaming started)")
            } else {
                status = "Failed: \(r.output)"
                log("Failed to turn Location Services off: \(r.output)")
            }
        } else if weDisabled && (!now || !enabled) {
            restore()
        }
    }

    func restore() {
        guard weDisabled else { return }
        let r = LocationServices.run("on")
        if r.ok {
            weDisabled = false
            status = "Location Services restored"
            log("Location Services ON (streaming stopped)")
        } else {
            status = "Restore failed: \(r.output)"
            log("Failed to restore Location Services: \(r.output)")
        }
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
        // Formatted by Guard's dateFormatter (medium time style).
        let f = DateFormatter()
        f.timeStyle = .medium
        return f.string(from: date)
    }
}
