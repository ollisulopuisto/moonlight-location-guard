import SwiftUI

@main
struct MoonlightLocationGuardApp: App {
    @StateObject private var guardian = Guard()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Disable Location Services while streaming", isOn: Binding(
                    get: { guardian.enabled }, set: { guardian.enabled = $0 }))
                Text(guardian.streaming ? "Moonlight fullscreen" : "Moonlight not streaming")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Text("Last toggled: \(guardian.lastToggledString)")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
                Text(guardian.status).font(.system(size: 11))
                Divider()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
            .padding(14).frame(width: 300)
        } label: {
            Image(nsImage: guardian.iconImage)
                .contextMenu {
                    if guardian.logEntries.isEmpty {
                        Text("No debug events yet")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    } else {
                        ForEach(guardian.logEntries.prefix(12)) { entry in
                            Text("\(entry.timestamp)  \(entry.message)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                        Button("Clear log") { guardian.logEntries.removeAll() }
                            .font(.system(size: 10))
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }

    init() { NSApplication.shared.setActivationPolicy(.accessory) }
}
