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
                Button(guardian.showDebugLog ? "Hide debug log" : "Show debug log") {
                    guardian.showDebugLog.toggle()
                }
                .font(.system(size: 11))
                if guardian.showDebugLog {
                    Divider()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(guardian.logEntries) { entry in
                                Text("\(entry.timestamp)  \(entry.message)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if guardian.logEntries.isEmpty {
                                Text("No events yet").font(.system(size: 10)).foregroundStyle(.tertiary)
                            }
                        }
                        .padding(4)
                    }
                    .frame(maxHeight: 140)
                    Button("Clear log") { guardian.logEntries.removeAll() }
                        .font(.system(size: 11))
                }
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
            .padding(14).frame(width: 300)
        } label: {
            Image(nsImage: guardian.iconImage)
        }
        .menuBarExtraStyle(.window)
    }

    init() { NSApplication.shared.setActivationPolicy(.accessory) }
}
