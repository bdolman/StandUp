//
//  PrefsAuthController.swift
//  StandUp
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
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
    
    fileprivate var desk: DeskOld? = nil {
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
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear() {
        accessTokenField.stringValue = settings.accessToken ?? ""
        deviceIdField.stringValue = settings.deviceId ?? ""
        updateStatus()
        super.viewWillAppear()
    }
    
    fileprivate func addDeskObservers() {
        guard let desk = desk else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(PrefsAuthController.deskStateChanged(_:)),
            name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: desk)
        NotificationCenter.default.addObserver(self, selector: #selector(PrefsAuthController.deskStateChanged(_:)),
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
        NotificationCenter.default.addObserver(self, selector: #selector(PrefsAuthController.activeDeskChanged(_:)),
            name: NSNotification.Name(rawValue: ActiveDeskDidChangeNotification), object: desks)
    }
    
    @objc func activeDeskChanged(_ notification: Notification) {
        desk = desks.activeDesk
    }
    
    func updateStatus() {
        var statusText = "Not connected"
        if let height = desk?.height {
            statusText = "Connected (Height: \(height) cm)"
        } else if let _ = desk {
            statusText = "Waiting for connection..."
        }
        statusField.stringValue = statusText
    }
    
    @IBAction func saveClicked(_ sender: AnyObject) {
        let newToken: String? = accessTokenField.stringValue != "" ? accessTokenField.stringValue : nil
        let newDeviceId: String? = deviceIdField.stringValue != "" ? deviceIdField.stringValue : nil
        
        if newToken != settings.accessToken || newDeviceId != settings.deviceId {
            settings.accessToken = newToken
            settings.deviceId = newDeviceId
            if let auth = settings.auth {
                let device = Device(accessToken: auth.accessToken, deviceId: auth.deviceId)
                let desk = DeskOld(device: device, sittingHeight: settings.sittingHeight, standingHeight: settings.standingHeight)
                desk.updateCurrentState()
                desks.activeDesk = desk
            } else {
                desks.activeDesk = nil
            }
        }
    }
}
