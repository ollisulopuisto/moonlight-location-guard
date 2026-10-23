# Moonlight Location Guard

A tiny macOS menu-bar app that automatically disables Location Services when you're playing Moonlight (GameStream) and re-enables them when you stop, so games streamed to your Mac don't think you're moving around.

## How it works

- Watches Moonlight's activity (via its logs / process state).
- When a game starts streaming, it turns macOS Location Services off.
- When streaming stops, it turns Location Services back on.

Because toggling Location Services requires root, a small root helper (`mlg-location`) is installed once via `install-helper.sh` and runs passwordless through a sudoers rule. The app itself runs as your user in the menu bar (`LSUIElement`).

## Files

- `Package.swift` — Swift package manifest (macOS 13+)
- `Sources/MoonlightLocationGuard/` — app source (Swift)
- `mlg-location` — root helper: `on|off|status`
- `install-helper.sh` — one-time install of the root helper + sudoers rule
- `build-app.sh` — builds a release `.app` into `dist/`

## Build & install

```bash
# Build the app
./build-app.sh

# Install the root helper (review first!)
./install-helper.sh

# Run
open dist/Moonlight\ Location\ Guard.app
```

## License

MIT
