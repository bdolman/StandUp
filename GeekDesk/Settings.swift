//
//  Settings.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Cocoa

private let accessTokenKey = "AccessToken"
private let deviceIdKey = "DeviceId"

class Settings: NSObject {
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    var auth: Auth? {
        get {
            guard let accessToken = self.accessToken, deviceId = self.deviceId else { return nil }
            return Auth(accessToken: accessToken, deviceId: deviceId)
        }
        set(newValue) {
            self.accessToken = newValue?.accessToken
            self.deviceId = newValue?.deviceId
        }
    }
    
    var accessToken: String? {
        get { return defaults.stringForKey(accessTokenKey) }
        set(newValue) { defaults.setObject(newValue, forKey: accessTokenKey) }
    }
    var deviceId: String? {
        get { return defaults.stringForKey(deviceIdKey) }
        set(newValue) { defaults.setObject(newValue, forKey: deviceIdKey) }
    }
}
