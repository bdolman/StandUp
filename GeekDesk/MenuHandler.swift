//
//  MenuHandler.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Foundation

private enum ItemType: Int {
    case Unknown
    case StandUp
    case SitDown
    case Height
    case State
    case Preferences
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
        case .Lowered: return "Sitting"
        case .Lowering: return "Lowering..."
        case .Raising: return "Raising..."
        case .Raised: return "Standing"
        }
    }
}

protocol MenuHandlerDelegate: NSObjectProtocol {
    func menuHandlerPreferencesItemClicked(menuHandler: MenuHandler)
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
    
    private var stateTitle: String {
        if let state = desk?.state {
            return state.title
        }
        return "Not Connected"
    }
    
    private func addDeskObservers() {
        guard let desk = desk else { return }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("heightChanged:"),
            name: DeskHeightChangedNotification, object: desk)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("stateChanged:"),
            name: DeskStateChangedNotification, object: desk)
    }
    
    private func removeDeskObservers() {
        guard let desk = desk else { return }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DeskHeightChangedNotification, object: desk)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DeskStateChangedNotification, object: desk)
    }
    
    override init() {
        super.init()
        let arrowModifierMask = Int(NSEventModifierFlags.ShiftKeyMask.rawValue | NSEventModifierFlags.CommandKeyMask.rawValue)
        
        // Stand Up
        let upArrowKey = String(Character(UnicodeScalar(NSUpArrowFunctionKey)))
        let standUpItem = NSMenuItem(title: "Stand Up", action: Selector("standUp:"), keyEquivalent: upArrowKey)
        standUpItem.tag = ItemType.StandUp.rawValue
        standUpItem.target = self
        standUpItem.keyEquivalentModifierMask = arrowModifierMask
        menu.addItem(standUpItem)
        
        // Sit Down
        let downArrowKey = String(Character(UnicodeScalar(NSDownArrowFunctionKey)))
        let sitDownItem = NSMenuItem(title: "Sit Down", action: Selector("sitDown:"), keyEquivalent: downArrowKey)
        sitDownItem.tag = ItemType.SitDown.rawValue
        sitDownItem.target = self
        sitDownItem.keyEquivalentModifierMask = arrowModifierMask
        menu.addItem(sitDownItem)
        
        menu.addItem(NSMenuItem.separatorItem())
        
        // Sit/Stand State
        let stateItem = NSMenuItem(title: "Sitting", action: Selector("ignore:"), keyEquivalent: "")
        stateItem.target = self
        stateItem.tag = ItemType.State.rawValue
        menu.addItem(stateItem)
        
        // Height
        let heightItem = NSMenuItem(title: "Height", action: Selector("ignore:"), keyEquivalent: "")
        heightItem.target = self
        heightItem.tag = ItemType.Height.rawValue
        menu.addItem(heightItem)
        
        menu.addItem(NSMenuItem.separatorItem())
        
        // Prefs
        let prefsItem = NSMenuItem(title: "Preferences...", action: Selector("showPreferences:"), keyEquivalent: ",")
        prefsItem.target = self
        prefsItem.tag = ItemType.Preferences.rawValue
        menu.addItem(prefsItem)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("heightChanged:"),
            name: DeskHeightChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("stateChanged:"),
            name: DeskStateChangedNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func sitDown(sender: AnyObject) {
        desk?.lower()
    }
    
    func standUp(sender: AnyObject) {
        desk?.raise()
    }
    
    func showPreferences(sender: AnyObject) {
        delegate?.menuHandlerPreferencesItemClicked(self)
    }
    
    func ignore(sender: AnyObject) {}
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        guard let itemType = menuItem.itemType else { return true }
        switch itemType {
        case .StandUp:
            return desk?.state == .Lowered
        case .SitDown:
            return desk?.state == .Raised
        case .Height:
            let height = desk?.height != nil ? "\(desk!.height!)" : "?"
            menuItem.title = "Height: \(height) cm"
            return false
        case .State:
            menuItem.title = stateTitle
            return false
        default: return true
        }
    }
    
    func stateChanged(notification: NSNotification) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.menu.update()
        }
    }
    
    func heightChanged(notification: NSNotification) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.menu.update()
        }
    }
}