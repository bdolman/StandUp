//
//  PrefsViewController.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Cocoa

class PrefsViewController: NSTabViewController {
    // Injected properties
    var desks: Desks!
    var settings: Settings!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        prepareChildViewControllers()
        super.viewWillAppear()
    }
    
    private func prepareChildViewControllers() {
        for viewController in childViewControllers {
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
