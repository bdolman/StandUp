//
//  MenuManager.swift
//  StandUp
//
//  Created by Ben Dolman on 10/26/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa

private enum ItemType: Int {
    case unknown
    case activeDesk
    case addDesk
    case desk
    case presetsHeader
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
    private var activeDeskObserver: NSKeyValueObservation?
    private var deskObservers = [NSKeyValueObservation]()
    
    init(menu: NSMenu, managedObjectContext: NSManagedObjectContext) {
        self.menu = menu
        self.managedObjectContext = managedObjectContext
        super.init()
        
        updateActiveDesk()
        rebuildDeskSelectionMenu()
        rebuildMenu()
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
        }
    }
    
    private func rebuildDeskSelectionMenu() {
        deskSelectionMenu.removeAllItems()
        
        fetchedResultsController.fetchedObjects!.forEach { (desk) in
            let deskItem = NSMenuItem(title: desk.name, action: #selector(changeActiveDesk(_:)), keyEquivalent: "")
            deskItem.target = self
            deskItem.state = (desk == activeDesk) ? .on : .off
            deskItem.representedObject = desk
            deskItem.tag = ItemType.desk.rawValue
            deskSelectionMenu.addItem(deskItem)
        }
    }
    
    private func rebuildMenu() {
        menu.removeAllItems()
        
        if let desk = activeDesk {
            // Active Desk
            let deskItem = NSMenuItem(title: "Desk: \(desk.name)", action: #selector(ignore(_:)), keyEquivalent: "")
            deskItem.target = self
            deskItem.tag = ItemType.activeDesk.rawValue
            if fetchedResultsController.sections![0].numberOfObjects > 1 {
                deskItem.submenu = deskSelectionMenu
            }
            menu.addItem(deskItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Desk State
            let stateItem = NSMenuItem(title: "Desk Status", action: #selector(ignore(_:)), keyEquivalent: "")
            stateItem.target = self
            stateItem.tag = ItemType.state.rawValue
            menu.addItem(stateItem)
            
            // Height
            let heightItem = NSMenuItem(title: "Height", action: #selector(ignore(_:)), keyEquivalent: "")
            heightItem.target = self
            heightItem.tag = ItemType.height.rawValue
            menu.addItem(heightItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Presets title
            let presetsItem = NSMenuItem(title: "Presets", action: #selector(ignore(_:)), keyEquivalent: "")
            presetsItem.target = self
            presetsItem.tag = ItemType.presetsHeader.rawValue
            menu.addItem(presetsItem)
            
            // Add a preset
            let addPresetItem = NSMenuItem(title: "Add a Preset...", action: #selector(addPreset(_:)), keyEquivalent: "")
            addPresetItem.target = self
            addPresetItem.tag = ItemType.addPreset.rawValue
            menu.addItem(addPresetItem)
        } else {
            // Add Desk
            let addDeskItem = NSMenuItem(title: "Add Desk...", action: #selector(showPreferences(_:)), keyEquivalent: "")
            addDeskItem.target = self
            addDeskItem.tag = ItemType.addDesk.rawValue
            menu.addItem(addDeskItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Prefs
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences(_:)), keyEquivalent: ",")
        prefsItem.target = self
        prefsItem.tag = ItemType.preferences.rawValue
        menu.addItem(prefsItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        quitItem.tag = ItemType.quit.rawValue
        menu.addItem(quitItem)
    }
    
    @objc private func ignore(_ sender: AnyObject) {}
    
    @objc func showPreferences(_ sender: AnyObject) {
        delegate?.menuManagerWantsPreferences(self, forDesk: nil)
    }
    
    @objc func addPreset(_ sender: AnyObject) {
        delegate?.menuManagerWantsPreferences(self, forDesk: activeDesk)
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
    
    @objc private func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let itemType = menuItem.itemType else { return true }
        switch itemType {
        case .activeDesk:
            if let desk = activeDesk {
                menuItem.title = "Desk: \(desk.name)"
            } else {
                menuItem.title = "Desk: --"
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
    var itemType: ItemType? {
        get {
            return ItemType(rawValue: tag)
        }
        set {
            if let type = itemType {
                tag = type.rawValue
            }
        }
    }
}
