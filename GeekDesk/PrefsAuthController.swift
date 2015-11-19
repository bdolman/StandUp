//
//  PrefsAuthController.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Cocoa

class PrefsAuthController: NSViewController {
    // Injected properties
    var desks: Desks! {
        didSet {
            self.desk = desks.activeDesk
            observeActiveDeskChanges()
        }
    }
    var settings: Settings!
    
    @IBOutlet weak var accessTokenField: NSTextField!
    @IBOutlet weak var deviceIdField: NSTextField!
    @IBOutlet weak var statusField: NSTextField!
    
    private var desk: Desk? {
        willSet {
            removeDeskObservers()
        }
        didSet {
            addDeskObservers()
            updateStatus()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear() {
        accessTokenField.stringValue = settings.accessToken ?? ""
        deviceIdField.stringValue = settings.deviceId ?? ""
        updateStatus()
        super.viewWillAppear()
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
    
    func updateStatus() {
        var statusText = "Not Connected"
        if let height = desk?.height {
            statusText = "Connected (Height: \(height) cm)"
        } else if let _ = desk {
            statusText = "Connected"
        }
        statusField.stringValue = statusText
    }
    
    @IBAction func saveClicked(sender: AnyObject) {
        let newToken: String? = accessTokenField.stringValue != "" ? accessTokenField.stringValue : nil
        let newDeviceId: String? = deviceIdField.stringValue != "" ? deviceIdField.stringValue : nil
        
        if newToken != settings.accessToken || newDeviceId != settings.deviceId {
            settings.accessToken = newToken
            settings.deviceId = newDeviceId
            if let auth = settings.auth {
                let device = Device(accessToken: auth.accessToken, deviceId: auth.deviceId)
                let desk = Desk(device: device)
                desk.updateCurrentState()
                desks.activeDesk = desk
            } else {
                desks.activeDesk = nil
            }
        }
    }
}