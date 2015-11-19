//
//  AppDelegate.swift
//  GeekDesk Helper
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if var pathComponents = NSBundle.mainBundle().bundleURL.pathComponents {
            let mainApp = Array(pathComponents[0..<(pathComponents.count - 4)])
            let mainAppPath = NSString.pathWithComponents(mainApp)
            let launched = NSWorkspace.sharedWorkspace().launchApplication(mainAppPath)
            NSLog("GeekDesk Helper launch result \(launched) \(mainAppPath)")
        }
    }

}

