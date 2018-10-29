//
//  MenuManager.swift
//  StandUp
//
//  Created by Ben Dolman on 10/26/18.
//  Copyright © 2018 Ben Dolman. All rights reserved.
//

import Cocoa
import UserNotifications

private enum MenuItemType: Int {
    case unknown
    case activeDesk
    case addDesk
    case desk
    case presetsHeader
    case preset
    case addPreset
    case height
    case state
    case preferences
    case quit
}

protocol MenuManagerDelegate: NSObjectProtocol {
    func menuManagerWantsPreferences(_ menuManager: MenuManager, forDesk desk: Desk?)
}

class MenuManager: NSObject {
    let menu: NSMenu
    let managedObjectContext: NSManagedObjectContext
    weak var delegate: MenuManagerDelegate? = nil
    
    private let deskSelectionMenu = NSMenu()
    private var activeDesk: Desk?
    private var targetPreset: Preset?
    private var targetPresetObserver: NSKeyValueObservation?
    
    init(menu: NSMenu, managedObjectContext: NSManagedObjectContext) {
        self.menu = menu
        self.managedObjectContext = managedObjectContext
        super.init()
        
        observePresetChanges()
        updateActiveDesk()
        rebuildDeskSelectionMenu()
        rebuildMenu()
        authorizeNotifications()
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Desk> = {
        let fetchRequest: NSFetchRequest<Desk> = Desk.fetchRequest()
        fetchRequest.sortDescriptors = [Desk.sortOrder(ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: self.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
    private func updateActiveDesk() {
        let newActiveDesk = Globals.globalsIn(managedObjectContext).activeDesk
        if newActiveDesk != activeDesk {
            activeDesk = newActiveDesk
            targetPreset = nil
            targetPresetObserver = nil
        }
    }
}

// MARK: - Notifications
extension MenuManager {
    private func authorizeNotifications() {
        if #available(OSX 10.14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: .alert) { (authorized, error) in
                if let error = error {
                    NSLog("Notification auth \(error)")
                }
            }
        }
    }
    
    private func presentStartNotification(forPreset preset: Preset) {
        guard let desk = preset.desk else { return }
        
        if #available(OSX 10.14, *) {
            let goingUp = desk.height <= preset.height
            let content = UNMutableNotificationContent()
            content.title = desk.name
            if goingUp {
                content.body = "Raising to \(preset.displayName) position (\(preset.height) cm)"
            } else {
                content.body = "Lowering to \(preset.displayName) position (\(preset.height) cm)"
            }
            let request = UNNotificationRequest(identifier: "position-notification", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    NSLog("Add notification error \(error)")
                }
            }
        }
    }
}

// MARK: - Menu validation
extension MenuManager {
    @objc private func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let itemType = menuItem.itemType else { return true }
        switch itemType {
        case .activeDesk:
            if let desk = activeDesk {
                menuItem.title = "\(desk.name)"
            } else {
                menuItem.title = "Desk"
            }
            if fetchedResultsController.sections![0].numberOfObjects > 1 {
                return true
            } else {
                return false
            }
        case .height:
            if let desk = activeDesk, desk.connectionState == .open, desk.isOnline {
                menuItem.title = "Height: \(desk.height) cm"
            } else {
                menuItem.title = "Height: --"
            }
            return false
        case .state:
            menuItem.title = activeDesk?.connectionStatusString ?? "--"
            return false
        case .presetsHeader:
            return false
        default:
            return true
        }
    }
}

// MARK: - Desk actions
extension MenuManager {
    private func raiseToNextPreset() {
        guard let desk = activeDesk else { return }
        var nextPreset: Preset?
        let presets = desk.heightOrderedPresets
        if let targetPreset = targetPreset, let index = presets.firstIndex(of: targetPreset) {
            if index + 1 < presets.count {
                nextPreset = presets[index + 1]
            }
        }
        if nextPreset == nil {
            nextPreset = presets.first { (preset) -> Bool in
                let toleranceRange = (preset.height - 1...preset.height + 1)
                return preset.height > desk.height && !toleranceRange.contains(desk.height)
            }
        }
        if let nextPreset = nextPreset {
            activate(preset: nextPreset)
        }
    }
    
    private func lowerToNextPreset() {
        guard let desk = activeDesk else { return }
        var nextPreset: Preset?
        let presets = Array(desk.heightOrderedPresets.reversed())
        if let targetPreset = targetPreset, let index = presets.firstIndex(of: targetPreset) {
            if index + 1 < presets.count {
                nextPreset = presets[index + 1]
            }
        }
        if nextPreset == nil {
            nextPreset = presets.first { (preset) -> Bool in
                let toleranceRange = (preset.height - 1...preset.height + 1)
                return preset.height < desk.height && !toleranceRange.contains(desk.height)
            }
        }
        if let nextPreset = nextPreset {
            activate(preset: nextPreset)
        }
    }
    
    private func activate(preset: Preset) {
        guard let desk = preset.desk else { return }
        
        NSLog("Setting Desk \"\(desk.name)\" to \(preset.height) cm")
        
        presentStartNotification(forPreset: preset)
        
        targetPreset = preset
        var targetPresetObserver: NSKeyValueObservation?
        targetPresetObserver = desk.observe(\.direction) { [weak self] (desk, change) in
            guard self?.targetPreset == preset, self?.targetPresetObserver == targetPresetObserver else { return }
            if desk.direction == .stopped {
                NSLog("reached target")
                self?.targetPreset = nil
                self?.targetPresetObserver = nil
            }
        }
        self.targetPresetObserver = targetPresetObserver

        desk.setHeight(Int(preset.height)) { (error) in
            if let error = error {
                NSLog("Error setting height \(error)")
                if self.targetPreset == preset {
                    self.targetPreset = nil
                }
                if self.targetPresetObserver == targetPresetObserver {
                    self.targetPresetObserver = nil
                }
            }
        }
    }
}

// MARK: - Menu actions
extension MenuManager {
    @objc private func ignore(_ sender: AnyObject) {}
    
    @objc private func showPreferences(_ sender: AnyObject) {
        delegate?.menuManagerWantsPreferences(self, forDesk: nil)
    }
    
    @objc private func addPreset(_ sender: AnyObject) {
        delegate?.menuManagerWantsPreferences(self, forDesk: activeDesk)
    }
    
    @objc private func menuPresetSelected(_ sender: AnyObject) {
        guard let preset = (sender as? NSMenuItem)?.representedObject as? Preset else { return }
        activate(preset: preset)
    }
    
    
    
    @objc func changeActiveDesk(_ sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem, let desk = menuItem.representedObject as? Desk else { return }
        guard activeDesk != desk else { return }
        Globals.globalsIn(managedObjectContext).activeDesk = desk
        try! managedObjectContext.save()
    }
    
    @objc func quitApp(_ sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }
}

// MARK: - Hot keys
extension MenuManager {
    private func updateGlobalHotKeys() {
        guard let hotKeyCenter = DDHotKeyCenter.shared() else { return }
        hotKeyCenter.unregisterAllHotKeys()
        guard let presets = activeDesk?.orderedPresets, presets.count > 0 else { return }
        
        HotKey.registerRaise { [weak self] (event) in
            self?.raiseToNextPreset()
        }
        HotKey.registerLowerHotKey { [weak self] (event) in
            self?.lowerToNextPreset()
        }
        
        presets.enumerated().forEach { (index, preset) in
            let presetNum = index + 1
            HotKey.registerPresetHotKey(Int32(presetNum), block: { [weak self] (event) in
                self?.activate(preset: preset)
            })
        }
        
    }
}

// MARK: - Menu building
extension MenuManager {
    private func rebuildDeskSelectionMenu() {
        deskSelectionMenu.removeAllItems()
        
        fetchedResultsController.fetchedObjects!.forEach { (desk) in
            let deskItem = NSMenuItem(title: desk.name, action: #selector(changeActiveDesk(_:)), keyEquivalent: "")
            deskItem.target = self
            deskItem.state = (desk == activeDesk) ? .on : .off
            deskItem.representedObject = desk
            deskItem.tag = MenuItemType.desk.rawValue
            deskSelectionMenu.addItem(deskItem)
        }
    }
    
    private func rebuildMenu() {
        menu.removeAllItems()
        
        if let desk = activeDesk {
            // Active Desk
            let deskItem = NSMenuItem(title: "\(desk.name)", action: #selector(ignore(_:)), keyEquivalent: "")
            deskItem.target = self
            deskItem.tag = MenuItemType.activeDesk.rawValue
            if fetchedResultsController.sections![0].numberOfObjects > 1 {
                deskItem.submenu = deskSelectionMenu
            }
            menu.addItem(deskItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Desk State
            let stateItem = NSMenuItem(title: "Desk Status", action: #selector(ignore(_:)), keyEquivalent: "")
            stateItem.target = self
            stateItem.tag = MenuItemType.state.rawValue
            menu.addItem(stateItem)
            
            // Height
            let heightItem = NSMenuItem(title: "Height", action: #selector(ignore(_:)), keyEquivalent: "")
            heightItem.target = self
            heightItem.tag = MenuItemType.height.rawValue
            menu.addItem(heightItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Presets title
            let presetsTitleItem = NSMenuItem(title: "Presets:", action: #selector(ignore(_:)), keyEquivalent: "")
            presetsTitleItem.target = self
            presetsTitleItem.tag = MenuItemType.presetsHeader.rawValue
            menu.addItem(presetsTitleItem)
            
            let presetModifierMask = Int(NSEvent.ModifierFlags.shift.rawValue | NSEvent.ModifierFlags.control.rawValue)
            desk.orderedPresets.enumerated().forEach { (index, preset) in
                let presetNum = index + 1
                let title = preset.displayName
                var keyEquivalent = ""
                if presetNum < 10 {
                    keyEquivalent = "\(presetNum)"
                }
                let presetItem = NSMenuItem(title: title, action: #selector(menuPresetSelected(_:)), keyEquivalent: keyEquivalent)
                presetItem.target = self
                presetItem.tag = MenuItemType.preset.rawValue
                presetItem.representedObject = preset
                presetItem.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: UInt(presetModifierMask))
                menu.addItem(presetItem)
            }
            
            if desk.presets.count == 0 {
                // Add a preset
                let addPresetItem = NSMenuItem(title: "Add a Preset...", action: #selector(addPreset(_:)), keyEquivalent: "")
                addPresetItem.target = self
                addPresetItem.tag = MenuItemType.addPreset.rawValue
                menu.addItem(addPresetItem)
            }
        } else {
            // Add Desk
            let addDeskItem = NSMenuItem(title: "Add Desk...", action: #selector(showPreferences(_:)), keyEquivalent: "")
            addDeskItem.target = self
            addDeskItem.tag = MenuItemType.addDesk.rawValue
            menu.addItem(addDeskItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Prefs
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences(_:)), keyEquivalent: ",")
        prefsItem.target = self
        prefsItem.tag = MenuItemType.preferences.rawValue
        menu.addItem(prefsItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        quitItem.tag = MenuItemType.quit.rawValue
        menu.addItem(quitItem)
        
        updateGlobalHotKeys()
    }
    
}

// MARK: - Change management
extension MenuManager {
    private func observePresetChanges() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidChange(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: managedObjectContext)
    }
    
    @objc private func contextDidChange(_ notification: Notification) {
        let changedPresets = notification.changedObjects(ofClass: Preset.self, keys: [NSUpdatedObjectsKey])
        let activeDeskPresetsChanged = changedPresets.contains(where: {$0.desk == activeDesk})
        if activeDeskPresetsChanged {
            rebuildMenu()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension MenuManager: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateActiveDesk()
        rebuildMenu()
        rebuildDeskSelectionMenu()
        deskSelectionMenu.update()
        menu.update()
    }
}


private extension NSMenuItem {
    var itemType: MenuItemType? {
        get {
            return MenuItemType(rawValue: tag)
        }
        set {
            if let type = itemType {
                tag = type.rawValue
            }
        }
    }
}
