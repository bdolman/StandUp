//
//  PreferencesViewController.swift
//  StandUp
//
//  Created by Ben Dolman on 10/18/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {
    // Injected properties
    var settings: Settings! {
        didSet {
            desks = settings.desks ?? []
        }
    }
    
    @IBOutlet weak var deskTableView: NSTableView!
    
    private var desks = [Desk]()
    
    private var dragDropType = NSPasteboard.PasteboardType(rawValue: "private.table-row")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deskTableView.registerForDraggedTypes([dragDropType])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        deskTableView.reloadData()
    }
    
    @IBAction func addDesk(_ sender: Any) {
    }
    
    @IBAction func removeDesk(_ sender: Any) {
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let deskConfigController = segue.destinationController as? DeskConfigurationViewController {
            deskConfigController.delegate = self
        }
    }
    
    private func saveDesks() {
        settings.desks = desks
    }
}

extension PreferencesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        
        let item = NSPasteboardItem()
        item.setString(String(row), forType: self.dragDropType)
        return item
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        if dropOperation == .above {
            return .move
        }
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        var oldIndexes = [Int]()
        info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:]) { dragItem, _, _ in
            if let str = (dragItem.item as! NSPasteboardItem).string(forType: self.dragDropType), let index = Int(str) {
                oldIndexes.append(index)
            }
        }
        
        var oldIndexOffset = 0
        var newIndexOffset = 0
        
        // For simplicity, the code below uses `tableView.moveRowAtIndex` to move rows around directly.
        // You may want to move rows in your content array and then call `tableView.reloadData()` instead.
        tableView.beginUpdates()
        for oldIndex in oldIndexes {
            let from: Int
            let to: Int
            if oldIndex < row {
                from = oldIndex + oldIndexOffset
                to = row - 1
                oldIndexOffset -= 1
            } else {
                from = oldIndex
                to = row + newIndexOffset
                newIndexOffset += 1
            }
            tableView.moveRow(at: from, to: to)
            desks.insert(desks.remove(at: from), at: to)
        }
        tableView.endUpdates()
        
        saveDesks()
        
        return true
    }
}

extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return desks.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return desks[row]
    }
}

extension PreferencesViewController: DeskConfigurationViewControllerDelegate {
    func deskConfigurationViewController(_ controller: DeskConfigurationViewController, savedDesk: Desk) {
        dismiss(controller)
        
        if let index = desks.firstIndex(of: savedDesk) {
            let cell = deskTableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? PreferencesDeskTableViewCell
            cell?.update(desk: savedDesk)
        } else {
            desks.append(savedDesk)
            deskTableView.reloadData()
        }
        
        saveDesks()
    }
}
