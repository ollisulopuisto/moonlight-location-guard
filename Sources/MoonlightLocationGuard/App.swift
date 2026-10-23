import SwiftUI

@main
struct MoonlightLocationGuardApp: App {
    @StateObject private var guardian = Guard()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 16) {
                // Header — feature toggle
                Toggle("Disable Location Services while streaming", isOn: Binding(
                    get: { guardian.enabled }, set: { guardian.enabled = $0 }))
                .toggleStyle(.switch)
                .font(.system(size: 12, weight: .medium))

                Divider()

                // Status row
                HStack(spacing: 10) {
                    Image(nsImage: guardian.iconImage)
                        .resizable()
                        .frame(width: 16, height: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(guardian.streaming ? "Moonlight streaming" : "Moonlight not streaming")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(guardian.streaming ? .primary : .secondary)
                        Text(guardian.status)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Last toggled (subtle)
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Text("Last toggled \(guardian.lastToggledString)")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 8)

                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
            .frame(width: 280)
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
