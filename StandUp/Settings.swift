//
//  Settings.swift
//  StandUp
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Cocoa

private let enabledAtLoginKey = "EnabledAtLogin"

class Settings: NSObject {
    fileprivate let defaults = UserDefaults.standard
    
    override init() {
        defaults.register(defaults: [
            enabledAtLoginKey : true
        ])
        super.init()
    }
    
    @objc var enabledAtLogin: Bool {
        get { return defaults.bool(forKey: enabledAtLoginKey) }
        set(newValue) { defaults.set(newValue, forKey: enabledAtLoginKey) }
    }
}
