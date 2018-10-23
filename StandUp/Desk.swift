//
//  Desk.swift
//  StandUp
//
//  Created by Ben Dolman on 10/22/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa

class Desk: NSObject, Codable {
    let deviceID: String
    @objc dynamic var accessToken: String
    @objc dynamic var name: String
    
    static func == (lhs: Desk, rhs: Desk) -> Bool {
        return lhs.deviceID == rhs.deviceID
    }
    
    init(deviceID: String, accessToken: String, name: String) {
        self.deviceID = deviceID
        self.accessToken = accessToken
        self.name = name
    }
    
    override var debugDescription: String {
        return "\(name) (\(deviceID))"
    }
}
