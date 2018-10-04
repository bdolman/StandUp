//
//  PrefsPresetsController.swift
//  StandUp
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Cocoa

class PrefsPresetsController: NSViewController {
    // Injected properties
    var desks: Desks! {
        didSet {
            self.desk = desks.activeDesk
            observeActiveDeskChanges()
        }
    }
    @objc dynamic var settings: Settings!
    
    @objc dynamic fileprivate var desk: Desk? = nil {
        willSet {
            desk?.pollForHeightChanges = false
            removeDeskObservers()
        }
        didSet {
            addDeskObservers()
            updateStatus()
            desk?.pollForHeightChanges = true
        }
    }
    
    @IBOutlet weak var standingField: NSTextField!
    @IBOutlet weak var sittingField: NSTextField!
    @IBOutlet weak var statusField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        desk?.pollForHeightChanges = true
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        desk?.pollForHeightChanges = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addDeskObservers() {
        guard let desk = desk else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(PrefsPresetsController.deskStateChanged(_:)),
            name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: desk)
        NotificationCenter.default.addObserver(self, selector: #selector(PrefsPresetsController.deskStateChanged(_:)),
            name: NSNotification.Name(rawValue: DeskHeightChangedNotification), object: desk)
    }
    
    fileprivate func removeDeskObservers() {
        guard let desk = desk else { return }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: desk)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DeskHeightChangedNotification), object: desk)
    }
    
    @objc func deskStateChanged(_ notification: Notification) {
        OperationQueue.main.addOperation {
            self.updateStatus()
        }
    }
    
    func observeActiveDeskChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(PrefsPresetsController.activeDeskChanged(_:)),
            name: NSNotification.Name(rawValue: ActiveDeskDidChangeNotification), object: desks)
    }
    
    @objc func activeDeskChanged(_ notification: Notification) {
        desk = desks.activeDesk
    }
    
    func updateButtonStatus() {
        
    }
    
    @IBAction func presetValueChanged(_ sender: AnyObject) {
        desk?.standingHeight = settings.standingHeight
        desk?.sittingHeight = settings.sittingHeight
    }
    
    func updateStatus() {
        updateButtonStatus()
        var statusText = "Not connected to desk"
        if let height = desk?.height {
            statusText = "Current Height: \(height) cm"
        } else if let _ = desk {
            statusText = "Waiting for connection..."
        }
        statusField.stringValue = statusText
    }
    
    @IBAction func standingUseCurrentHeightClicked(_ sender: AnyObject) {
        if let height = desk?.height {
            standingField.stringValue = String(height)
        }
    }
    @IBAction func sittingUseCurrentHeightClicked(_ sender: AnyObject) {
        if let height = desk?.height {
            sittingField.stringValue = String(height)
        }
    }
    
}
