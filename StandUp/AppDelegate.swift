//
//  AppDelegate.swift
//  StandUp
//
//  Created by Ben Dolman on 11/16/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    
    private var persistentContainer: NSPersistentContainer?
    private let settings = Settings()
    private var menuHandler: MenuHandler?
    private var statusItemManager: StatusItemManager?
    private var prefsController: PrefsWindowController? = nil
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        loadDataModel()
    }
}

// MARK: - Data model
extension AppDelegate {
    private func loadDataModel(retriesRemaining: Int = 1) {
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
                self.loadDataModel(retriesRemaining: retriesRemaining - 1)
            } else {
                self.didLoadDataModel(persistentContainer: container)
            }
        }
    }
    
    private func didLoadDataModel(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        
        loadAllDesks()
        updateLoginState()
        
        menuHandler = MenuHandler()
        menuHandler?.delegate = self
        
        setupStatusItem()
        
        // Show prefs is no desk is configured
        let fetchRequest: NSFetchRequest<Desk> = Desk.fetchRequest()
        let desks = try! persistentContainer.viewContext.fetch(fetchRequest)
        if desks.count == 0 {
            showPreferences()
        }
    }
    
    // Faults in all desks so that they start their network connections
    private func loadAllDesks() {
        guard let context = persistentContainer?.viewContext else { return }
        let fetchRequest: NSFetchRequest<Desk> = Desk.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        let _ = try! context.fetch(fetchRequest)
    }
}

// MARK: - Status Icon
extension AppDelegate {
    private func setupStatusItem() {
        guard let context = persistentContainer?.viewContext else { return }
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItemManager = StatusItemManager(statusItem: statusItem, managedObjectContext: context)
        statusItemManager?.delegate = self
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
    private func showPreferences(selectDesk: Desk? = nil) {
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
        
        if let desk = selectDesk {
            prefsController?.selectDesk(desk: desk)
        }
    }
    
    @objc func prefsClosed(_ notification: Notification) {
        guard let prefsController = self.prefsController else { return }
        self.prefsController = nil
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: prefsController)
    }
}

// MARK: - MenuHandlerDelegate
extension AppDelegate: MenuHandlerDelegate {
    func menuHandlerPreferencesItemClicked(_ menuHandler: MenuHandler) {
        showPreferences()
    }
}

// MARK: - StatusItemManagerDelegate
extension AppDelegate: StatusItemManagerDelegate {
    func statusItemManagerWantsPreferences(_ statusItemManager: StatusItemManager, forDesk desk: Desk?) {
        showPreferences(selectDesk: desk)
    }
}
