//
//  AppDelegate.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/16/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Cocoa

extension DeskState {
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
    
    let accessToken = "8b9ebdc77f38b9cd69c95767f512d692cae586d5"
    let deviceId = "3a0024000447343337373739"
    
    var menuHandler: MenuHandler!
    var device: Device!
    var desk: Desk!
    
    let statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    
    func registerGlobalShortcuts() {
        HotKey.registerRaiseHotKey { event in
            self.desk.raise()
        }
        HotKey.registerLowerHotKey { event in
            self.desk.lower()
        }
    }
    
    func setupStatusItem() {
        registerGlobalShortcuts()
        statusItem.menu = menuHandler.menu
        // Initial state
        if let button = statusItem.button {
            button.target = self
            button.action = Selector("statusItemClicked:")
        }
    }
    
    func updateStatusIcon() {
        if let image = desk.state?.image {
            statusItem.button?.image = image
        }
    }
    
    func observeDeskStateChanges() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("deskStateChanged:"), name: DeskStateChangedNotification, object: desk)
    }
    
    func deskStateChanged(notification: NSNotification) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.updateStatusIcon()
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        device = Device(accessToken: accessToken, deviceId: deviceId)
        desk = Desk(device: device)
        menuHandler = MenuHandler()
        menuHandler.desk = desk
        setupStatusItem()
        observeDeskStateChanges()
        desk.updateCurrentState()
    }

//    func statusItemClicked(sender: AnyObject) {
//        let rightClick = NSApp.currentEvent?.type == .RightMouseDown
//        
//        if rightClick {
//            print("right click")
//        } else if let flags = NSApp.currentEvent?.modifierFlags where flags.contains(.AlternateKeyMask) {
//            print("option")
//        } else {
////            switch deskState {
////            case .Lowered: deskState = .Raising
////            case .Raising: deskState = .Raised
////            case .Raised: deskState = .Lowering
////            case .Lowering: deskState = .Lowered
////            }
//        }
//    }
}

