//
//  Settings.swift
//  StandUp
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Cocoa

private let accessTokenKey = "AccessToken"
private let deviceIdKey = "DeviceId"
private let standingHeightKey = "StandingHeight"
private let sittingHeightKey = "SittingHeight"
private let enabledAtLoginKey = "EnabledAtLogin"
private let desksKey = "Desks"

class Settings: NSObject {
    fileprivate let defaults = UserDefaults.standard
    
    override init() {
        defaults.register(defaults: [
            standingHeightKey : 100,
            sittingHeightKey : 60,
            enabledAtLoginKey : true
        ])
        super.init()
    }
    
    var auth: Auth? {
        get {
            guard let accessToken = self.accessToken, let deviceId = self.deviceId else { return nil }
            return Auth(accessToken: accessToken, deviceId: deviceId)
        }
        set(newValue) {
            self.accessToken = newValue?.accessToken
            self.deviceId = newValue?.deviceId
        }
    }
    
    @objc var accessToken: String? {
        get { return defaults.string(forKey: accessTokenKey) }
        set(newValue) { defaults.set(newValue, forKey: accessTokenKey) }
    }
    @objc var deviceId: String? {
        get { return defaults.string(forKey: deviceIdKey) }
        set(newValue) { defaults.set(newValue, forKey: deviceIdKey) }
    }
    
    @objc var standingHeight: Int {
        get { return defaults.integer(forKey: standingHeightKey) }
        set(newValue) { defaults.set(newValue, forKey: standingHeightKey) }
    }
    @objc var sittingHeight: Int {
        get { return defaults.integer(forKey: sittingHeightKey) }
        set(newValue) { defaults.set(newValue, forKey: sittingHeightKey) }
    }
    @objc var enabledAtLogin: Bool {
        get { return defaults.bool(forKey: enabledAtLoginKey) }
        set(newValue) { defaults.set(newValue, forKey: enabledAtLoginKey) }
    }
    
    var desks: [DeskStatic]? {
        get {
            guard let data = defaults.data(forKey: desksKey) else {
                return nil
            }
            do {
                let decoder = JSONDecoder()
                let desks = try decoder.decode([DeskStatic].self, from: data)
                return desks
            } catch {
                NSLog("Error reading desks \(error)")
                return nil
            }
        }
        set {
            if let desks = newValue {
                let encoder = JSONEncoder()
                do {
                    let encoded = try encoder.encode(desks)
                    defaults.set(encoded, forKey: desksKey)
                } catch {
                    NSLog("Error saving desks \(error)")
                }
            } else {
                defaults.set(nil, forKey: desksKey)
            }
        }
    }
}
