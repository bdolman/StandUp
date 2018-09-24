//
//  Desks.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Foundation

let ActiveDeskDidChangeNotification = "ActiveDeskDidChangeNotification"

class Desks: NSObject {
    var activeDesk: Desk? = nil {
        didSet(oldValue) {
            guard oldValue !== activeDesk else { return }
            NotificationCenter.default.post(name: Notification.Name(rawValue: ActiveDeskDidChangeNotification), object: self)
        }
    }
}
