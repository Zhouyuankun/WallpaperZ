//
//  AppDelegate.swift
//  WallpaperZ
//
//  Created by celeglow on 2021/11/6.
//

import Cocoa
import AVKit

var settings: Settings?

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    
    var window: NSWindow!
    var playerView: AVPlayerView!
    var player: AVPlayer!

    func setupView(_ url: URL) {
        playVideo(url)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) {[weak self] noti in
            guard let strongSelf = self else { return }
            strongSelf.player.seek(to: CMTime.zero)
            strongSelf.player.play()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(changeVideo), name: Notification.Name("videourl"), object: nil)
    }
    
    func playVideo(_ url: URL) {
        let url = url
        
        let filepath = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent(url.getFileName()!+".png")
        if FileManager.default.fileExists(atPath: filepath.path) {
            refreshDesktop(filepath)
        } else {
            if url == Bundle.main.url(forResource: "demo", withExtension: "mp4")! {
                refreshDesktop(Bundle.main.url(forResource: "demo", withExtension: "png")!)
            } else {
                refreshDesktop(FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("tmp.png"))
            }
            
        }

        player = AVPlayer(url: url)
        player.isMuted = true
        playerView.player = player
        playerView.controlsStyle = AVPlayerViewControlsStyle.none
        player.play()
        
    }
    
    func refreshDesktop(_ dstURL: URL) {
        try? NSWorkspace.shared.setDesktopImageURL(URL(fileURLWithPath: ""), for: NSScreen.main!, options: [:])
        usleep(useconds_t(0.4 * Double(USEC_PER_SEC)))
        try? NSWorkspace.shared.setDesktopImageURL(dstURL, for: NSScreen.main!, options: [:])
    }
    
    @objc func changeVideo(notification: NSNotification) {
        if let url = notification.object as? URL {
            playVideo(url)
        }
    }
    
    @objc func allTheme() {
        let mainStoryBoard = NSStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryBoard.instantiateController(withIdentifier: "allThemeController") as? AllThemeViewController
        let windowController = mainStoryBoard.instantiateController(withIdentifier: "backWindow") as! NSWindowController
        windowController.showWindow(self)
        windowController.contentViewController = viewController
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("StatusBarButtonImage"))
            //button.action = #selector(printQuote)
        }
        constructMenu()
        
        let rect = NSRect(x: 0, y: 0, width: NSScreen.main!.frame.width, height: NSScreen.main!.frame.height)
        playerView = AVPlayerView()
        
        window = NSWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = NSColor.clear
        window.hasShadow = false
        window.isMovableByWindowBackground = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.contentView = playerView
        window.center()
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(self)
        
        if !FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("config.json").path) {
            settings = Settings(use: -1, names: [])
            setupView(Bundle.main.url(forResource: "demo", withExtension: "mp4")!)
        } else {
            settings = getSettingFromJSON(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("config.json"))
            if settings!.use == -1 {
                setupView(Bundle.main.url(forResource: "demo", withExtension: "mp4")!)
            } else {
                setupView(FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0].appendingPathComponent(settings!.names[settings!.use]+".mp4"))
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        writeSettingsToJSON(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("config.json"), settings: settings!)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func constructMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "New theme", action: #selector(AppDelegate.showPanel), keyEquivalent: "N"))
        menu.addItem(NSMenuItem(title: "All theme", action: #selector(AppDelegate.allTheme), keyEquivalent: "A"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "Q"))
        statusItem.menu = menu
    }
    
    @objc func showPanel() {
        let mainStoryBoard = NSStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryBoard.instantiateController(withIdentifier: "backController") as? NewThemeViewController
        let windowController = mainStoryBoard.instantiateController(withIdentifier: "backWindow") as! NSWindowController
        windowController.showWindow(self)
        windowController.contentViewController = viewController
        
    }
    
    func getThumbnailImageFromVideoUrl(size: NSSize, url: URL, completion: @escaping ((_ image: NSImage?)->Void)) {
        DispatchQueue.global().async { //1
            let asset = AVAsset(url: url) //2
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) //3
            avAssetImageGenerator.appliesPreferredTrackTransform = true //4
            let thumnailTime = CMTimeMake(value: 2, timescale: 1) //5
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) //6
                let thumbImage = NSImage(cgImage: cgThumbImage, size: size) //7
                DispatchQueue.main.async { //8
                    completion(thumbImage) //9
                }
            } catch {
                print(error.localizedDescription) //10
                DispatchQueue.main.async {
                    completion(nil) //11
                }
            }
        }
    }

}

extension NSImage {
    func saveTo(_ dstURL: URL) {
        if FileManager.default.fileExists(atPath: dstURL.path) {
            do {
                try FileManager.default.removeItem(at: dstURL)
            } catch (let error) {
                print(error)
            }
        }
        let bMImg = NSBitmapImageRep(data: self.tiffRepresentation!)
        let dataToSave = bMImg?.representation(using: .png, properties: [NSBitmapImageRep.PropertyKey.compressionFactor : 1])
        do {
            try dataToSave?.write(to: dstURL)
        } catch(let error) {
            print(error.localizedDescription)
        }
    }
}

