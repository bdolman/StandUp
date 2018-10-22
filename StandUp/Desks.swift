//
//  Desks.swift
//  StandUp
//
//  Created by Ben Dolman on 11/18/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Foundation

let ActiveDeskDidChangeNotification = "ActiveDeskDidChangeNotification"

class Desks: NSObject {
    var activeDesk: DeskOld? = nil {
        didSet(oldValue) {
            guard oldValue !== activeDesk else { return }
            NotificationCenter.default.post(name: Notification.Name(rawValue: ActiveDeskDidChangeNotification), object: self)
        }
    }
}
