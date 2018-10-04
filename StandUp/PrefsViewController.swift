//
//  PrefsViewController.swift
//  StandUp
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Cocoa

class PrefsViewController: NSTabViewController {
    // Injected properties
    var desks: Desks!
    var settings: Settings!

    override func viewWillAppear() {
        if desks.activeDesk == nil {
            selectedTabViewItemIndex = 0
        } else {
            selectedTabViewItemIndex = 1
        }
        prepareChildViewControllers()
        super.viewWillAppear()
    }
    
    fileprivate func prepareChildViewControllers() {
        for viewController in children {
            if let authController = viewController as? PrefsAuthController {
                authController.desks = desks
                authController.settings = settings
            }
            if let presetsController = viewController as? PrefsPresetsController {
                presetsController.desks = desks
                presetsController.settings = settings
            }
        }
    }
}
