import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    // QuickTime처럼: 파일 없이 실행되면(또는 창 없이 Dock 아이콘을 누르면) 열기 패널을 띄운다.
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        NSDocumentController.shared.openDocument(nil)
        return true
    }
}

func makeMainMenu() -> NSMenu {
    let mainMenu = NSMenu()

    let appItem = NSMenuItem()
    let appMenu = NSMenu()
    appMenu.addItem(withTitle: "About SkipPlayer",
                    action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
    appMenu.addItem(.separator())
    appMenu.addItem(withTitle: "Quit SkipPlayer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    appItem.submenu = appMenu
    mainMenu.addItem(appItem)

    let fileItem = NSMenuItem()
    let fileMenu = NSMenu(title: "File")
    fileMenu.addItem(withTitle: "Open File…",
                     action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
    fileMenu.addItem(.separator())
    fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    fileItem.submenu = fileMenu
    mainMenu.addItem(fileItem)

    // QuickTime과 같은 View > Enter Full Screen (⌃⌘F). 제목은 NSWindow가 Enter/Exit로 바꿔준다.
    let viewItem = NSMenuItem()
    let viewMenu = NSMenu(title: "View")
    let fullScreenItem = viewMenu.addItem(withTitle: "Enter Full Screen",
                                          action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
    fullScreenItem.keyEquivalentModifierMask = [.command, .control]
    viewItem.submenu = viewMenu
    mainMenu.addItem(viewItem)

    let windowItem = NSMenuItem()
    let windowMenu = NSMenu(title: "Window")
    windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
    windowItem.submenu = windowMenu
    mainMenu.addItem(windowItem)
    NSApp.windowsMenu = windowMenu

    return mainMenu
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.mainMenu = makeMainMenu()
app.setActivationPolicy(.regular)
app.run()
