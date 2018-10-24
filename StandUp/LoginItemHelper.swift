//
//  LoginItemHelper.swift
//  StandUp
//
//  Created by Ben Dolman on 10/23/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa
import ServiceManagement

class LoginItemHelper: NSObject {
    static func setLoginState(enabled: Bool) {
        let identifier = Bundle.main.bundleIdentifier! + "-Helper"
        if SMLoginItemSetEnabled(identifier as CFString, enabled) == false {
            NSLog("Login item was not successful")
        }
    }
}
