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
    
    private var persistentContainer: NSPersistentContainer?
    private let settings = Settings()
    private var menuHandler: MenuHandler?
    private var prefsController: PrefsWindowController? = nil
    private let statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        loadPersistentContainer()
    }
}

// MARK: - Data model
extension AppDelegate {
    private func loadPersistentContainer(retriesRemaining: Int = 1) {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                NSLog("Error loading persistent store \(error)")
                guard retriesRemaining > 0 else {
                    fatalError("Model failure. Unable to load or reset.")
                }
                guard let modelURL = description.url else {
                    fatalError("Model failure. Unable to load or reset.")
                }
                do {
                    try container.persistentStoreCoordinator.destroyPersistentStore(at: modelURL, ofType: description.type, options: description.options)
                    NSLog("Successfully reset store at \(modelURL)")
                } catch {
                    NSLog("Error deleting store. Will retry anyway. \(error)")
                }
                self.loadPersistentContainer(retriesRemaining: retriesRemaining - 1)
            } else {
                self.didLoad(persistentContainer: container)
            }
        }
    }
    
    private func didLoad(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        
        updateLoginState()
        
        menuHandler = MenuHandler()
        menuHandler?.delegate = self
        
        registerGlobalShortcutHandlers()
        
        setupStatusItem()
        updateStatusIcon()
        
        showPreferences()
    }
}

// MARK: - Hotkeys
extension AppDelegate {
    func registerGlobalShortcutHandlers() {
        // TODO
        //        HotKey.registerRaise { event in
        //            self.desk?.raise()
        //        }
        //        HotKey.registerLowerHotKey { event in
        //            self.desk?.lower()
        //        }
    }
}

// MARK: - Status Icon
extension AppDelegate {
    private func setupStatusItem() {
        statusItem.menu = menuHandler?.menu
    }
    
    private func updateStatusIcon() {
        // TODO
//        if let image = desk?.state?.image {
//            statusItem.button?.image = image
//        } else {
//            statusItem.button?.image = DeskState.raising.image
//        }
    }
}

// MARK: - Login Helper
extension AppDelegate {
    private func updateLoginState() {
        LoginItemHelper.setLoginState(enabled: settings.enabledAtLogin)
    }
}

// MARK: - Preferences Window
extension AppDelegate {
    private func showPreferences() {
        if prefsController == nil {
            let storyboard = NSStoryboard(name: "Preferences", bundle: Bundle.main)
            prefsController = storyboard.instantiateInitialController() as? PrefsWindowController
            prefsController?.managedObjectContext = persistentContainer?.viewContext
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

