import SwiftUI

@main
struct MoonlightLocationGuardApp: App {
    @StateObject private var guardian = Guard()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 16) {
                // Master toggle
                HStack(spacing: 10) {
                    Text("Disable Location Services while streaming")
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Toggle("", isOn: $guardian.enabled)
                        .toggleStyle(.switch)
                }

                Divider()

                // Per-app toggles — labels left, controls right-aligned
                VStack(alignment: .leading, spacing: 8) {
                    Text("Watch for streaming:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    ForEach(guardian.targets) { target in
                        HStack(spacing: 10) {
                            Text(target.displayName)
                                .font(.system(size: 11))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("", isOn: Binding(
                                get: { guardian.targetEnabledState[target.bundleID] ?? false },
                                set: { guardian.setTargetEnabled(target.bundleID, enabled: $0) }
                            ))
                            .toggleStyle(.switch)
                        }
                    }
                }

                Divider()

                // Status row
                HStack(spacing: 10) {
                    Image(nsImage: guardian.iconImage)
                        .resizable()
                        .frame(width: 16, height: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(guardian.streamingApp.map { "Streaming: \($0)" } ?? "Not streaming")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(guardian.streaming ? .primary : .secondary)
                        Text(guardian.status)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Last toggled
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Text("Last toggled \(guardian.lastToggledString)")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 10)

                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
            .frame(width: 300)
        } label: {
            Image(nsImage: guardian.iconImage)
                .contextMenu {
                    if guardian.logEntries.isEmpty {
                        Text("No debug events yet")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    } else {
                        ForEach(guardian.logEntries.prefix(12)) { entry in
                            Text("\(entry.timestamp)  \(entry.message)")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                        Button("Clear log") { guardian.logEntries.removeAll() }
                            .font(.system(size: 9.5))
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }

    init() { NSApplication.shared.setActivationPolicy(.accessory) }
}
