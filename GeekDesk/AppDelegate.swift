//
//  AppDelegate.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/16/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Cocoa

extension DeskState {
    var image: NSImage {
        switch self {
        case .Lowered: return NSImage(named: "desk-sit")!
        case .Lowering: return NSImage(named: "desk-stand-busy")!
        case .Raised: return NSImage(named: "desk-stand")!
        case .Raising: return NSImage(named: "desk-sit-busy")!
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    
    let accessToken = "8b9ebdc77f38b9cd69c95767f512d692cae586d5"
    let deviceId = "3a0024000447343337373739"
    
    var menuHandler: MenuHandler!
    let settings = Settings()
    let desks = Desks()
    var desk: Desk? = nil {
        willSet {
            removeDeskObservers()
        }
        didSet {
            addDeskObservers()
            menuHandler.desk = desk
            updateStatusIcon()
        }
    }
    var prefsController: PrefsWindowController? = nil
    let statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    
    func registerGlobalShortcutHandlers() {
        HotKey.registerRaiseHotKey { event in
            self.desk?.raise()
        }
        HotKey.registerLowerHotKey { event in
            self.desk?.lower()
        }
    }
    
    private func addDeskObservers() {
        guard let desk = desk else { return }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("deskStateChanged:"),
            name: DeskStateChangedNotification, object: desk)
    }
    
    private func removeDeskObservers() {
        guard let desk = desk else { return }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DeskStateChangedNotification, object: desk)
    }
    
    func setupStatusItem() {
        statusItem.menu = menuHandler.menu
        // Initial state
        if let button = statusItem.button {
            button.target = self
            button.action = Selector("statusItemClicked:")
        }
    }
    
    func updateStatusIcon() {
        if let image = desk?.state?.image {
            statusItem.button?.image = image
        } else {
            statusItem.button?.image = DeskState.Lowered.image
        }
    }
    
    func observeActiveDeskChanges() {
         NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("activeDeskChanged:"),
            name: ActiveDeskDidChangeNotification, object: desks)
    }
    
    func deskStateChanged(notification: NSNotification) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.updateStatusIcon()
        }
    }
    
    func activeDeskChanged(notification: NSNotification) {
        desk = desks.activeDesk
    }
    
    func savedDesk() -> Desk? {
        if let auth = settings.auth {
            let device = Device(accessToken: auth.accessToken, deviceId: auth.deviceId)
            return Desk(device: device, sittingHeight: settings.sittingHeight, standingHeight: settings.standingHeight)
        } else {
            return nil
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        menuHandler = MenuHandler()
        menuHandler.delegate = self
        setupStatusItem()
        registerGlobalShortcutHandlers()
        
        desks.activeDesk = savedDesk()
        desk = desks.activeDesk
        desk?.updateCurrentState()
        observeActiveDeskChanges()
        
        updateStatusIcon()
        
        if desk == nil {
            showPreferences()
        }
    }
    
    func showPreferences() {
        if prefsController == nil {
            let storyboard = NSStoryboard(name: "Preferences", bundle: NSBundle.mainBundle())
            prefsController = storyboard.instantiateInitialController() as? PrefsWindowController
            prefsController?.desks = desks
            prefsController?.settings = settings
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("prefsClosed:"),
                name: NSWindowWillCloseNotification, object: prefsController)
        }
        prefsController?.showWindow(self)
        prefsController?.window?.makeKeyAndOrderFront(self)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    func prefsClosed(notification: NSNotification) {
        guard let prefsController = self.prefsController else { return }
        self.prefsController = nil
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSWindowWillCloseNotification, object: prefsController)
    }
}

extension AppDelegate: MenuHandlerDelegate {
    func menuHandlerPreferencesItemClicked(menuHandler: MenuHandler) {
        showPreferences()
    }
}

