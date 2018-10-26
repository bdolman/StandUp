//
//  StatusItemManager.swift
//  StandUp
//
//  Created by Ben Dolman on 10/26/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa

class StatusItemManager: NSObject {
    let statusItem: NSStatusItem
    let managedObjectContext: NSManagedObjectContext
    
    private let menuManager: MenuManager
    private var activeDesk: Desk?
    private var activeDeskObserver: NSKeyValueObservation?
    private var deskObservers = [NSKeyValueObservation]()
    
    init(statusItem: NSStatusItem, managedObjectContext: NSManagedObjectContext) {
        self.statusItem = statusItem
        self.managedObjectContext = managedObjectContext
        
        let menu = NSMenu()
        statusItem.menu = menu
        self.menuManager = MenuManager(menu: menu, managedObjectContext: managedObjectContext)
        
        super.init()
        
        setupActiveDeskObserver()
        updateActiveDesk()
    }
    
    private func setupActiveDeskObserver() {
        activeDeskObserver = Globals.globalsIn(managedObjectContext).observe(\.activeDesk) { [weak self] (globals, change) in
            self?.updateActiveDesk()
        }
    }
    
    private func updateActiveDesk() {
        activeDesk = Globals.globalsIn(managedObjectContext).activeDesk
        updateDeskObservers()
        updateStatusIcon()
    }
    
    private func updateDeskObservers() {
        deskObservers.removeAll()
        guard let activeDesk = activeDesk else { return }
        
        let changeHandler = { [weak self] (desk: Desk, _: Any) -> Void in
            self?.updateStatusIcon()
        }
        
        deskObservers.append(contentsOf: [
            activeDesk.observe(\.direction, changeHandler: changeHandler),
            activeDesk.observe(\.connectionState, changeHandler: changeHandler),
            activeDesk.observe(\.isOnline, changeHandler: changeHandler)
        ])
    }
    
    private func updateStatusIcon() {
        var image = NSImage(named: "menu-bar")
        if let activeDesk = activeDesk {
            switch (activeDesk.connectionState, activeDesk.isOnline, activeDesk.direction) {
            case (.connecting, _, _):
                image = NSImage(named: "menu-bar-busy")
            case (.closed, _, _): fallthrough
            case (.open, false, _):
                image = NSImage(named: "menu-bar-alert")
            case (.open, true, .stopped):
                image = NSImage(named: "menu-bar")
            case (.open, true, .up):
                image = NSImage(named: "menu-bar-up")
            case (.open, true, .down):
                image = NSImage(named: "menu-bar-down")
            default:
                image = NSImage(named: "menu-bar")
            }
        }
        statusItem.button?.image = image
    }
}
