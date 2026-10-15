import AppKit
import AVFoundation

/// QuickTime의 MGPlaybackDocument에 해당: 영상 하나 = 문서 하나.
@objc(PlayerDocument)
final class PlayerDocument: NSDocument {
    private(set) var player: AVPlayer?

    override func read(from url: URL, ofType typeName: String) throws {
        player = AVPlayer(url: url)
    }

    override func makeWindowControllers() {
        guard let player else { return }
        addWindowController(PlayerWindowController(player: player))
    }

    override func close() {
        player?.pause()
        super.close()
    }
}
