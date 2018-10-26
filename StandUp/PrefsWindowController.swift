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
    var managedObjectContext: NSManagedObjectContext!
    var settings: Settings!
    
    override func showWindow(_ sender: Any?) {
        if let prefsViewController = contentViewController as? PreferencesViewController {
            prefsViewController.managedObjectContext = managedObjectContext
            prefsViewController.settings = settings
        }
        super.showWindow(sender)
    }
    
    func selectDesk(desk: Desk) {
        (contentViewController as? PreferencesViewController)?.selectDesk(desk: desk)
    }
}
