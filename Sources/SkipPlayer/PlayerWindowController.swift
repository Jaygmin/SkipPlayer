import AppKit
import AVKit

/// QuickTime의 플레이어 창에 해당. ←/→ 5초 스킵, ↑/↓ 볼륨, Space 재생/일시정지.
final class PlayerWindowController: NSWindowController, NSWindowDelegate {
    private let player: AVPlayer
    private let skipInterval = CMTime(seconds: 5, preferredTimescale: 600)
    private let volumeStep: Float = 0.1
    private var pendingSeekTarget: CMTime?
    private var keyMonitor: Any?

    init(player: AVPlayer) {
        self.player = player

        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .floating

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 540),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.contentView = playerView
        window.center()
        super.init(window: window)
        window.delegate = self

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            return self.handleKey(event) ? nil : event
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func windowWillClose(_ notification: Notification) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    /// 처리한 키면 true (AVPlayerView 기본 동작인 프레임 이동을 막는다).
    private func handleKey(_ event: NSEvent) -> Bool {
        if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty { return false }
        switch event.keyCode {
        case 123: skip(by: CMTimeMultiply(skipInterval, multiplier: -1)) // ←
        case 124: skip(by: skipInterval)                                  // →
        case 126: changeVolume(by: volumeStep)                            // ↑
        case 125: changeVolume(by: -volumeStep)                           // ↓
        case 49:  togglePlayPause()                                       // Space
        default:  return false
        }
        return true
    }

    private func skip(by delta: CMTime) {
        guard let item = player.currentItem else { return }
        let base = pendingSeekTarget ?? player.currentTime()
        var target = CMTimeMaximum(CMTimeAdd(base, delta), .zero)
        if item.duration.isNumeric {
            target = CMTimeMinimum(target, item.duration)
        }
        pendingSeekTarget = target
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard finished else { return }
            DispatchQueue.main.async {
                if self?.pendingSeekTarget == target { self?.pendingSeekTarget = nil }
            }
        }
    }

    private func changeVolume(by delta: Float) {
        player.volume = min(max(player.volume + delta, 0), 1)
    }

    private func togglePlayPause() {
        guard let item = player.currentItem else { return }
        if player.rate == 0 {
            if item.duration.isNumeric, CMTimeCompare(player.currentTime(), item.duration) >= 0 {
                player.seek(to: .zero)
            }
            player.play()
        } else {
            player.pause()
        }
    }
}
