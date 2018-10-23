//
//  PreferencesDeskTableViewCell.swift
//  StandUp
//
//  Created by Ben Dolman on 10/22/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa

class PreferencesDeskTableViewCell: NSTableCellView {
    @IBOutlet weak var deskImageView: NSImageView!
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var statusField: NSTextField!
    
    func update(desk: Desk) {
        titleField.stringValue = desk.name
        
        let statusString: String
        switch (desk.connectionState, desk.connectionError) {
        case (.connecting, _):
            statusString = "Connecting..."
        case (.open, _):
            statusString = "Connected"
        case (.closed, .some):
            statusString = "Error"
        case (.closed, .none):
            statusString = "Disconnected"
        }
        statusField.stringValue = statusString
    }
    
    override var objectValue: Any? {
        didSet {
            if let desk = objectValue as? Desk {
                update(desk: desk)
            }
        }
    }
}
