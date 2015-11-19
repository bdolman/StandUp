//
//  PrefsPresetsController.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
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
    dynamic var settings: Settings!
    
    dynamic private var desk: Desk? = nil {
        willSet {
            removeDeskObservers()
        }
        didSet {
            addDeskObservers()
            updateStatus()
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
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func addDeskObservers() {
        guard let desk = desk else { return }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("deskStateChanged:"),
            name: DeskStateChangedNotification, object: desk)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("deskStateChanged:"),
            name: DeskHeightChangedNotification, object: desk)
    }
    
    private func removeDeskObservers() {
        guard let desk = desk else { return }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DeskStateChangedNotification, object: desk)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DeskHeightChangedNotification, object: desk)
    }
    
    func deskStateChanged(notification: NSNotification) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.updateStatus()
        }
    }
    
    func observeActiveDeskChanges() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("activeDeskChanged:"),
            name: ActiveDeskDidChangeNotification, object: desks)
    }
    
    func activeDeskChanged(notification: NSNotification) {
        desk = desks.activeDesk
    }
    
    func updateButtonStatus() {
        
    }
    
    @IBAction func presetValueChanged(sender: AnyObject) {
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
    
    @IBAction func standingUseCurrentHeightClicked(sender: AnyObject) {
        if let height = desk?.height {
            standingField.stringValue = String(height)
        }
    }
    @IBAction func sittingUseCurrentHeightClicked(sender: AnyObject) {
        if let height = desk?.height {
            sittingField.stringValue = String(height)
        }
    }
    
}
