//
//  AllThemeViewController.swift
//  WallpaperZ
//
//  Created by celeglow on 2021/11/6.
//

import Cocoa

class AllThemeViewController: NSViewController {
    
    
    
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var themeBox: NSComboBox!
    
    @IBOutlet weak var deleteButton: NSButton!
    
    @IBOutlet weak var renameButton: NSButton!
    
    @IBOutlet weak var applyButton: NSButton!
    
    var currentIndex: Int!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        guard let settings = settings else {
//            return
//        }
        deleteButton.action = #selector(deleteTheme)
        renameButton.action = #selector(renameTheme)
        applyButton.action = #selector(applyTheme)
        themeBox.usesDataSource = true
        themeBox.delegate = self
        themeBox.dataSource = self
        
    }
    
    @objc func applyTheme() {
        guard let current = currentIndex else {
            return
        }
        settings!.use = current
        NotificationCenter.default.post(name: Notification.Name("videourl"), object: FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0].appendingPathComponent(settings!.names[current]+".mp4"))
    }
    
    @objc func renameTheme() {
        guard let current = currentIndex else {
            return
        }
        let alert = NSAlert()
        alert.messageText = "Please enter a name for theme"
        alert.informativeText = settings!.names[current]
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = ("Enter your theme name")
        alert.accessoryView = inputTextField
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn && inputTextField.stringValue != "" && !fileExists(inputTextField.stringValue) {
            //save
            let mp4Dire = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0].appendingPathComponent(settings!.names[current]+".mp4")
            try! FileManager.default.moveItem(at: mp4Dire, to: FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0].appendingPathComponent(inputTextField.stringValue+".mp4"))
            
            let pngDire = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent(settings!.names[current]+".png")
            try! FileManager.default.moveItem(at: pngDire, to: FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent(inputTextField.stringValue+".png"))
            
            settings!.names[current] = inputTextField.stringValue
            
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
    
    @objc func deleteTheme() {
        guard let current = currentIndex else {
            return
        }
        if settings!.use == current {
            settings!.use = -1
        }
        currentIndex = nil
        imageView.image = nil
        try! FileManager.default.removeItem(at: FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent(settings!.names[current]+".png"))
        try! FileManager.default.removeItem(at: FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0].appendingPathComponent(settings!.names[current]+".mp4"))
        settings!.names.remove(at: current)
        themeBox.reloadData()

    }
    

    
}

extension URL {
    func getFileName() -> String?{
        if self.isFileURL {
            return self.deletingPathExtension().lastPathComponent
        }
        return nil
    }
}

extension AllThemeViewController: NSComboBoxDataSource, NSComboBoxDelegate {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return settings!.names.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return settings!.names[index]
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comBox = notification.object as! NSComboBox
        currentIndex = comBox.indexOfSelectedItem
        guard currentIndex < settings!.names.count && settings!.names.count != 0 else { return }
        imageView.image = NSImage(contentsOf: FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent(settings!.names[currentIndex]+".png"))
    }
    
    
}
