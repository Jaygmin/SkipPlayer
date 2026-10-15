<p align="center">
  <img src="docs/icon.png" width="160" alt="SkipPlayer icon">
</p>

<h1 align="center">SkipPlayer</h1>

<p align="center">A minimal macOS video player that skips 5 seconds with the arrow keys.</p>

QuickTime Player has no key for jumping a few seconds back or forward. SkipPlayer keeps the same simple,
document-based design (one window per video, built on AVKit's `AVPlayerView`) and adds the keyboard
shortcuts people expect from YouTube or VLC.

## Keyboard shortcuts

| Key | Action |
|---|---|
| ← / → | Skip back / forward 5 seconds (stops at the start and end) |
| ↑ / ↓ | Volume up / down by 10% |
| Space | Play / pause (restarts from the beginning when at the end) |
| ⌘O | Open a video |
| ⌘W | Close the window |

Holding an arrow key keeps skipping. Repeated presses add up even while a seek is still in progress.

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9 or later. Xcode is not required; the Command Line Tools are enough
  (`xcode-select --install`).

## Build and run

```sh
git clone https://github.com/Jaygmin/SkipPlayer.git
cd SkipPlayer
./build-app.sh
open SkipPlayer.app
```

`build-app.sh` builds a release binary with SwiftPM, assembles `SkipPlayer.app` and signs it locally
(ad-hoc). To open a file directly, run `open -a "$PWD/SkipPlayer.app" movie.mp4`. You can also drag
`SkipPlayer.app` into `/Applications` and choose it from Finder's **Open With** menu.

## Security

- The app runs in the **App Sandbox** with a single entitlement:
  `com.apple.security.files.user-selected.read-only`. It can only read files you open, and it has no
  network, camera or microphone access.
- It is signed with the **Hardened Runtime** enabled.
- It has no third-party dependencies.

## Project layout

```
Sources/SkipPlayer/
  main.swift                    App delegate and menu bar
  PlayerDocument.swift          One NSDocument per video, owns the AVPlayer
  PlayerWindowController.swift  Player window and keyboard handling
Info.plist                      Bundle metadata and supported file types
SkipPlayer.entitlements         Sandbox entitlements
build-app.sh                    Build, bundle and sign
scripts/make-icon.swift         Regenerates Resources/AppIcon.icns and docs/icon.png
```

## License

[MIT](LICENSE) © 2026 Jay Min
