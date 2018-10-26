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
    case height
    case state
    case preferences
    case quit
}

class MenuManager: NSObject {
    let menu: NSMenu
    let managedObjectContext: NSManagedObjectContext
    
    private var activeDesk: Desk?
    private var activeDeskObserver: NSKeyValueObservation?
    private var deskObservers = [NSKeyValueObservation]()
    
    init(menu: NSMenu, managedObjectContext: NSManagedObjectContext) {
        self.menu = menu
        self.managedObjectContext = managedObjectContext
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
    }
    
    private func updateDeskObservers() {
        deskObservers.removeAll()
        guard let activeDesk = activeDesk else { return }
        
        let changeHandler = { [weak self] (desk: Desk, _: Any) -> Void in
            //self?.updateStatusIcon()
        }
        
        deskObservers.append(contentsOf: [
            activeDesk.observe(\.direction, changeHandler: changeHandler),
            activeDesk.observe(\.connectionState, changeHandler: changeHandler)
        ])
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
