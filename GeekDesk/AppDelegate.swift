//
//  AppDelegate.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/16/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Cocoa

enum DeskState {
    case Lowered
    case Lowering
    case Raised
    case Raising
    
    var image: NSImage {
        switch self {
        case .Lowered: return NSImage(named: "desk-sit")!
        case .Lowering: return NSImage(named: "desk-stand-busy")!
        case .Raised: return NSImage(named: "desk-stand")!
        case .Raising: return NSImage(named: "desk-sit-busy")!
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    let statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    var deskState: DeskState = .Lowered {
        didSet {
            statusItem.button?.image = deskState.image
        }
    }
    
    func registerGlobalShortcuts() {
        HotKey.registerRaiseHotKey { event in
            self.deskState = .Raising
        }
        HotKey.registerLowerHotKey { event in
            self.deskState = .Lowering
        }
    }
    
    func enableRightClick() {
        let mask = Int(NSEventMask.LeftMouseDownMask.rawValue | NSEventMask.RightMouseDownMask.rawValue)
        statusItem.button?.sendActionOn(mask)
    }
    
    func addMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Test", action: Selector("statusItemClicked:"), keyEquivalent: "P"))
//        statusItem.menu = menu
    }
    
    func setupStatusItem() {
        enableRightClick()
        registerGlobalShortcuts()
        addMenu()
        // Initial state
        if let button = statusItem.button {
            button.image = deskState.image
            button.target = self
            button.action = Selector("statusItemClicked:")
        }
    }
    
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        setupStatusItem()
    }

    func statusItemClicked(sender: AnyObject) {
        let rightClick = NSApp.currentEvent?.type == .RightMouseDown
        
        if rightClick {
            print("right click")
        } else if let flags = NSApp.currentEvent?.modifierFlags where flags.contains(.AlternateKeyMask) {
            print("option")
        } else {
            switch deskState {
            case .Lowered: deskState = .Raising
            case .Raising: deskState = .Raised
            case .Raised: deskState = .Lowering
            case .Lowering: deskState = .Lowered
            }
        }
    }
}

