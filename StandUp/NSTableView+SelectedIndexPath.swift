//
//  NSTableView+SelectedIndexPath.swift
//  StandUp
//
//  Created by Ben Dolman on 10/28/18.
//  Copyright © 2018 Ben Dolman. All rights reserved.
//

import Cocoa

extension NSTableView {
    var selectedIndexPath: IndexPath? {
        guard selectedRow >= 0 else { return nil }
        return IndexPath(item: selectedRow, section: 0)
    }
}
