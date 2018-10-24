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
    
    func update(desk: DeskStatic) {
        titleField.stringValue = desk.name
        statusField.stringValue = desk.connectionStatusString
    }
    
    override var objectValue: Any? {
        didSet {
            if let desk = objectValue as? DeskStatic {
                update(desk: desk)
            }
        }
    }
}
