//
//  AppDelegate.swift
//  StandUp Helper
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        var pathComponents = Bundle.main.bundleURL.pathComponents
        let mainApp = Array(pathComponents[0..<(pathComponents.count - 4)])
        let mainAppPath = NSString.path(withComponents: mainApp)
        let launched = NSWorkspace.shared.launchApplication(mainAppPath)
        NSLog("StandUp Helper launch result \(launched) \(mainAppPath)")
    }

}

