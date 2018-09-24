//
//  MenuHandler.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Foundation

private enum ItemType: Int {
    case unknown
    case standUp
    case sitDown
    case height
    case state
    case preferences
    case quit
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

private extension DeskState {
    var title: String {
        switch self {
        case .lowered: return "Sitting"
        case .lowering: return "Lowering..."
        case .raising: return "Raising..."
        case .raised: return "Standing"
        }
    }
}

protocol MenuHandlerDelegate: NSObjectProtocol {
    func menuHandlerPreferencesItemClicked(_ menuHandler: MenuHandler)
}

class MenuHandler: NSObject {
    weak var delegate: MenuHandlerDelegate? = nil
    var desk: Desk? = nil {
        willSet {
            removeDeskObservers()
        }
        didSet {
            addDeskObservers()
            menu.update()
        }
    }
    let menu = NSMenu()
    
    fileprivate var stateTitle: String {
        if let state = desk?.state {
            return state.title
        }
        return "Not Connected"
    }
    
    fileprivate func addDeskObservers() {
        guard let desk = desk else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(MenuHandler.heightChanged(_:)),
            name: NSNotification.Name(rawValue: DeskHeightChangedNotification), object: desk)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuHandler.stateChanged(_:)),
            name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: desk)
    }
    
    fileprivate func removeDeskObservers() {
        guard let desk = desk else { return }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DeskHeightChangedNotification), object: desk)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: desk)
    }
    
    override init() {
        super.init()
        let arrowModifierMask = Int(NSEventModifierFlags.shift.rawValue | NSEventModifierFlags.command.rawValue)
        
        // Stand Up
        let upArrowKey = String(Character(UnicodeScalar(NSUpArrowFunctionKey)!))
        let standUpItem = NSMenuItem(title: "Stand Up", action: #selector(MenuHandler.standUp(_:)), keyEquivalent: upArrowKey)
        standUpItem.tag = ItemType.standUp.rawValue
        standUpItem.target = self
        standUpItem.keyEquivalentModifierMask = NSEventModifierFlags(rawValue: UInt(arrowModifierMask))
        menu.addItem(standUpItem)
        
        // Sit Down
        let downArrowKey = String(Character(UnicodeScalar(NSDownArrowFunctionKey)!))
        let sitDownItem = NSMenuItem(title: "Sit Down", action: #selector(MenuHandler.sitDown(_:)), keyEquivalent: downArrowKey)
        sitDownItem.tag = ItemType.sitDown.rawValue
        sitDownItem.target = self
        sitDownItem.keyEquivalentModifierMask = NSEventModifierFlags(rawValue: UInt(arrowModifierMask))
        menu.addItem(sitDownItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Sit/Stand State
        let stateItem = NSMenuItem(title: "Sitting", action: #selector(MenuHandler.ignore(_:)), keyEquivalent: "")
        stateItem.target = self
        stateItem.tag = ItemType.state.rawValue
        menu.addItem(stateItem)
        
        // Height
        let heightItem = NSMenuItem(title: "Height", action: #selector(MenuHandler.ignore(_:)), keyEquivalent: "")
        heightItem.target = self
        heightItem.tag = ItemType.height.rawValue
        menu.addItem(heightItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Prefs
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(MenuHandler.showPreferences(_:)), keyEquivalent: ",")
        prefsItem.target = self
        prefsItem.tag = ItemType.preferences.rawValue
        menu.addItem(prefsItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(MenuHandler.quitApp(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MenuHandler.heightChanged(_:)),
            name: NSNotification.Name(rawValue: DeskHeightChangedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuHandler.stateChanged(_:)),
            name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func sitDown(_ sender: AnyObject) {
        desk?.lower()
    }
    
    func standUp(_ sender: AnyObject) {
        desk?.raise()
    }
    
    func showPreferences(_ sender: AnyObject) {
        delegate?.menuHandlerPreferencesItemClicked(self)
    }
    
    func quitApp(_ sender: AnyObject) {
        NSApplication.shared().terminate(self)
    }
    
    func ignore(_ sender: AnyObject) {}
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let itemType = menuItem.itemType else { return true }
        switch itemType {
        case .standUp:
            return desk?.state == .lowered
        case .sitDown:
            return desk?.state == .raised
        case .height:
            let height = desk?.height != nil ? "\(desk!.height!)" : "?"
            menuItem.title = "Height: \(height) cm"
            return false
        case .state:
            menuItem.title = stateTitle
            return false
        default: return true
        }
    }
    
    func stateChanged(_ notification: Notification) {
        OperationQueue.main.addOperation {
            self.menu.update()
        }
    }
    
    func heightChanged(_ notification: Notification) {
        OperationQueue.main.addOperation {
            self.menu.update()
        }
    }
}
