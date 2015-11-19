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
private let standingHeightKey = "StandingHeight"
private let sittingHeightKey = "SittingHeight"
private let enabledAtLoginKey = "EnabledAtLogin"

class Settings: NSObject {
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    override init() {
        defaults.registerDefaults([
            standingHeightKey : 100,
            sittingHeightKey : 60,
            enabledAtLoginKey : true
        ])
        super.init()
    }
    
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
    
    var standingHeight: Int {
        get { return defaults.integerForKey(standingHeightKey) }
        set(newValue) { defaults.setInteger(newValue, forKey: standingHeightKey) }
    }
    var sittingHeight: Int {
        get { return defaults.integerForKey(sittingHeightKey) }
        set(newValue) { defaults.setInteger(newValue, forKey: sittingHeightKey) }
    }
    var enabledAtLogin: Bool {
        get { return defaults.boolForKey(enabledAtLoginKey) }
        set(newValue) { defaults.setBool(newValue, forKey: enabledAtLoginKey) }
    }
}
