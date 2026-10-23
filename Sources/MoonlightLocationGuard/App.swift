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
                Text(guardian.status).font(.system(size: 11))
                Divider()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
            .padding(14).frame(width: 300)
        } label: {
            Image(systemName: guardian.iconName)
        }
        .menuBarExtraStyle(.window)
    }

    init() { NSApplication.shared.setActivationPolicy(.accessory) }
}
