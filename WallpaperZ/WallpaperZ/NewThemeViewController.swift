//
//  ViewController.swift
//  WallpaperZ
//
//  Created by celeglow on 2021/11/6.
//

import Cocoa
import AVFoundation
import AVKit
import AppKit

class NewThemeViewController: NSViewController {
    
    
    @IBOutlet weak var fileButton: NSButton!
    
    @IBOutlet weak var imageView: NSImageView!
    
    
    @IBOutlet weak var saveThemeButton: NSButton!
    
    @IBOutlet weak var applyButton: NSButton!
    
    
    var image: NSImage?
    
    var videourl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fileButton.action = #selector(openDialog)
        saveThemeButton.action = #selector(saveTheme)
        applyButton.action = #selector(applyPaper)
        imageView.imageScaling = NSImageScaling.scaleProportionallyDown
        if let image = image {
            imageView.image = image
            
        }
    }
    
    override func viewDidAppear() {
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc func saveTheme() {
        guard let videourl = videourl else {
            return
        }

        let alert = NSAlert()
        alert.messageText = "Please enter a name for theme"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = ("Enter your theme name")
        alert.accessoryView = inputTextField
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn && inputTextField.stringValue != "" && !fileExists(inputTextField.stringValue) {
            //save
            let videoDirectory = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
            let newDire = videoDirectory.appendingPathComponent(inputTextField.stringValue+".mp4")
            do {
                try FileManager.default.copyItem(at: videourl, to: newDire)
                try FileManager.default.copyItem(at: FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("tmp.png"), to: FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent(inputTextField.stringValue+".png"))
                settings?.names.append(inputTextField.stringValue)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            let alert1 = NSAlert()
            alert1.messageText = "Save success"
            alert1.addButton(withTitle: "OK")
            alert1.runModal()
            
        } else {
            let alert2 = NSAlert()
            alert2.messageText = "Save failed"
            alert2.addButton(withTitle: "OK")
            alert2.runModal()
        }
    }
    
    func fileExists(_ name: String) -> Bool {
        let dstURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0].appendingPathComponent(name+".mp4")
        return FileManager.default.fileExists(atPath: dstURL.path)
    }
    
    
    @objc func openDialog() {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose an video";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = false;
        dialog.allowedFileTypes        = ["mp4"];

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            guard let result = dialog.url else {
                return
            }
            let path: String = result.path
            self.getThumbnailImageFromVideoUrl(url: URL(fileURLWithPath: path), completion: { (smallImage, bigImage) in
                self.imageView.image = smallImage
                //bigImage
                bigImage!.saveTo(FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("tmp.png"))
            })
            videourl = result

            print(path)
            // path contains the file path e.g
            // /Users/ourcodeworld/Desktop/tiger.jpeg
            
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @objc func applyPaper() {
        guard let videourl = videourl else {
            return
        }
        NotificationCenter.default.post(name: Notification.Name("videourl"), object: videourl)

    }
    
    func getThumbnailImageFromVideoUrl(url: URL, completion: @escaping ((_ smallImage: NSImage?, _ bigImage: NSImage?)->Void)) {
        DispatchQueue.global().async { //1
            let asset = AVAsset(url: url) //2
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) //3
            avAssetImageGenerator.appliesPreferredTrackTransform = true //4
            let thumnailTime = CMTimeMake(value: 2, timescale: 1) //5
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) //6
                let smallImage = NSImage(cgImage: cgThumbImage, size: NSSize(width: 384, height: 216)) //7
                let bigImage = NSImage(cgImage: cgThumbImage, size: NSSize(width: NSScreen.main!.frame.width, height: NSScreen.main!.frame.height))
                DispatchQueue.main.async { //8
                    completion(smallImage, bigImage) //9
                }
            } catch {
                print(error.localizedDescription) //10
                DispatchQueue.main.async {
                    completion(nil, nil) //11
                }
            }
        }
    }
    
    func secureCopyItem(at srcURL: URL, to dstURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
        }
    }


}
