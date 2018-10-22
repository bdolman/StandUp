//
//  MenuHandler.swift
//  StandUp
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
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
    var desk: DeskOld? = nil {
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
        let arrowModifierMask = Int(NSEvent.ModifierFlags.shift.rawValue | NSEvent.ModifierFlags.command.rawValue)
        
        // Stand Up
        let upArrowKey = String(Character(UnicodeScalar(NSEvent.SpecialKey.upArrow.rawValue)!))
        let standUpItem = NSMenuItem(title: "Stand Up", action: #selector(MenuHandler.standUp(_:)), keyEquivalent: upArrowKey)
        standUpItem.tag = ItemType.standUp.rawValue
        standUpItem.target = self
        standUpItem.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: UInt(arrowModifierMask))
        menu.addItem(standUpItem)
        
        // Sit Down
        let downArrowKey = String(Character(UnicodeScalar(NSEvent.SpecialKey.downArrow.rawValue)!))
        let sitDownItem = NSMenuItem(title: "Sit Down", action: #selector(MenuHandler.sitDown(_:)), keyEquivalent: downArrowKey)
        sitDownItem.tag = ItemType.sitDown.rawValue
        sitDownItem.target = self
        sitDownItem.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: UInt(arrowModifierMask))
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
        quitItem.target = self
        quitItem.tag = ItemType.quit.rawValue
        menu.addItem(quitItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MenuHandler.heightChanged(_:)),
            name: NSNotification.Name(rawValue: DeskHeightChangedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuHandler.stateChanged(_:)),
            name: NSNotification.Name(rawValue: DeskStateChangedNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func sitDown(_ sender: AnyObject) {
        desk?.lower()
    }
    
    @objc func standUp(_ sender: AnyObject) {
        desk?.raise()
    }
    
    @objc func showPreferences(_ sender: AnyObject) {
        delegate?.menuHandlerPreferencesItemClicked(self)
    }
    
    @objc func quitApp(_ sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func ignore(_ sender: AnyObject) {}
    
    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
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
        default:
            return true
        }
    }
    
    @objc func stateChanged(_ notification: Notification) {
        OperationQueue.main.addOperation {
            self.menu.update()
        }
    }
    
    @objc func heightChanged(_ notification: Notification) {
        OperationQueue.main.addOperation {
            self.menu.update()
        }
    }
}
