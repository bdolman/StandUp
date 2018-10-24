//
//  AppDelegate.swift
//  StandUp
//
//  Created by Ben Dolman on 11/16/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Cocoa
import ServiceManagement

extension DeskState {
    var image: NSImage {
        switch self {
        case .lowered: return NSImage(named: "desk-sit")!
        case .lowering: return NSImage(named: "desk-stand-busy")!
        case .raised: return NSImage(named: "desk-stand")!
        case .raising: return NSImage(named: "desk-sit-busy")!
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    
    var menuHandler: MenuHandler!
    let settings = Settings()
    let desks = Desks()
    var desk: DeskOld? = nil {
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
    let statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    func registerGlobalShortcutHandlers() {
        HotKey.registerRaise { event in
            self.desk?.raise()
        }
        HotKey.registerLowerHotKey { event in
            self.desk?.lower()
        }
    }
    
    fileprivate func addDeskObservers() {
        guard let desk = desk else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.deskStateChanged(_:)),
            name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: desk)
    }
    
    fileprivate func removeDeskObservers() {
        guard let desk = desk else { return }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: desk)
    }
    
    func setupStatusItem() {
        statusItem.menu = menuHandler.menu
    }
    
    func updateStatusIcon() {
        if let image = desk?.state?.image {
            statusItem.button?.image = image
        } else {
            statusItem.button?.image = DeskState.raising.image
        }
    }
    
    func observeActiveDeskChanges() {
         NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.activeDeskChanged(_:)),
            name: NSNotification.Name(rawValue: ActiveDeskDidChangeNotification), object: desks)
    }
    
    @objc func deskStateChanged(_ notification: Notification) {
        OperationQueue.main.addOperation {
            self.updateStatusIcon()
        }
    }
    
    @objc func activeDeskChanged(_ notification: Notification) {
        desk = desks.activeDesk
    }
    
    func savedDesk() -> DeskOld? {
        if let auth = settings.auth {
            let device = DeviceOld(accessToken: auth.accessToken, deviceId: auth.deviceId)
            return DeskOld(device: device, sittingHeight: settings.sittingHeight, standingHeight: settings.standingHeight)
        } else {
            return nil
        }
    }
    
    func updateLoginState() {
        LoginItemHelper.setLoginState(enabled: settings.enabledAtLogin)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        updateLoginState()
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
            let storyboard = NSStoryboard(name: "Preferences", bundle: Bundle.main)
            prefsController = storyboard.instantiateInitialController() as? PrefsWindowController
            prefsController?.desks = desks
            prefsController?.settings = settings
            NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.prefsClosed(_:)),
                name: NSWindow.willCloseNotification, object: prefsController)
        }
        prefsController?.showWindow(self)
        prefsController?.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func prefsClosed(_ notification: Notification) {
        guard let prefsController = self.prefsController else { return }
        self.prefsController = nil
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: prefsController)
    }
}

extension AppDelegate: MenuHandlerDelegate {
    func menuHandlerPreferencesItemClicked(_ menuHandler: MenuHandler) {
        showPreferences()
    }
}

