# Moonlight Location Guard

A tiny macOS menu-bar app that automatically disables Location Services when you're streaming games (Moonlight, Steam Link, Parsec) and re-enables them when you stop, so games streamed to your Mac don't think you're moving around.

## How it works

- Watches for Moonlight, Steam Link, and/or Parsec running fullscreen (each app has its own toggle — enable only the ones you use).
- When a game starts streaming, it turns macOS Location Services off.
- When streaming stops, it turns Location Services back on.

Because toggling Location Services requires root, a small root helper (`mlg-location`) is installed once via `install-helper.sh` and runs passwordless through a sudoers rule. The app itself runs as your user in the menu bar (`LSUIElement`).

## Files

- `Package.swift` — Swift package manifest (macOS 13+)
- `Sources/MoonlightLocationGuard/` — app source (Swift)
  - `App.swift` — menu bar UI
  - `Guard.swift` — state machine + polling + on/off logic
  - `AppIcon.swift` — hand-drawn shield icon (blue outline inactive, red filled active)
  - `LocationServices.swift` — wraps the root helper (`on|off|status`)
  - `StreamDetector.swift` — fullscreen detection for streaming apps
- `mlg-location` — root helper: `on|off|status`
- `install-helper.sh` — one-time install of the root helper + sudoers rule
- `build-app.sh` — builds a release `.app` into `dist/`
- `.github/workflows/build.yml` — CI/CD: builds on every push and tag

## Build & install

```bash
# Build the app
./build-app.sh

# Install the root helper (review first — it writes to /etc/sudoers.d)
./install-helper.sh

# Run
open dist/Moonlight\ Location\ Guard.app
```

## Menu bar icon

A custom gaming-style shield icon:
- **Inactive:** blue outline — Location Services is on / not streaming.
- **Active:** red filled — Location Services is off because a game is streaming fullscreen.

Right-click / option-click the icon to see the recent debug log (last 12 on/off events with timestamps).

## Supported apps

| App | Bundle ID | Toggle |
|-----|-----------|--------|
| Moonlight | `com.moonlight-stream.Moonlight` | Yes |
| Steam Link | `com.valvesoftware.steamlink` | Yes |
| Parsec | `com.parsecgame.parsec` | Yes |

All are enabled by default. Uncheck any app in the menu to stop watching it.

## CI/CD

Every push and tag triggers a GitHub Actions workflow that builds the Swift package in release mode on macOS. Releases are created from annotated tags.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE](LICENSE) for the full text.
