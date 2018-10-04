//
//  PrefsWindowController.swift
//  StandUp
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Cocoa

class PrefsWindowController: NSWindowController {
    // Injected properties
    var desks: Desks!
    var settings: Settings!
    
    override func showWindow(_ sender: Any?) {
        if let prefsViewController = contentViewController as? PrefsViewController {
            prefsViewController.desks = desks
            prefsViewController.settings = settings
        }
        super.showWindow(sender)
    }
}