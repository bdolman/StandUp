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
    var settings: Settings!
    
    @IBOutlet weak var deskTableView: NSTableView!
    @IBOutlet weak var emptyStateBox: NSBox!
    @IBOutlet weak var deskDetailBox: NSBox!
    
    private var desks = [Desk]()
    
    private var dragDropType = NSPasteboard.PasteboardType(rawValue: "private.table-row")
    
    private weak var deskDetailViewController: PreferencesDeskDetailViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deskTableView.registerForDraggedTypes([dragDropType])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        loadDesks()
    }
    
    @IBAction func removeDesk(_ sender: Any) {
        let selectedIndex = deskTableView.selectedRow
        guard selectedIndex >= 0 else { return }
        
        desks.remove(at: selectedIndex)
        deskTableView.removeRows(at: IndexSet([selectedIndex]), withAnimation: .effectFade)
        
        if desks.count > 0 {
            let newSelectedIndex = max(0,selectedIndex - 1)
            deskTableView.selectRowIndexes(IndexSet(integer: newSelectedIndex), byExtendingSelection: false)
        }
        
        saveDesks()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let deskConfigController = segue.destinationController as? DeskConfigurationViewController {
            deskConfigController.delegate = self
        }
        if let deskDetailController = segue.destinationController as? PreferencesDeskDetailViewController {
            deskDetailViewController = deskDetailController
        }
    }
    
    private func loadDesks() {
        desks = settings.desks ?? []
        deskTableView.reloadData()
        updateDeskDetail()
    }
    
    private func saveDesks() {
        settings.desks = desks
    }
    
    private func updateDeskDetail() {
        let selectedIndex = deskTableView.selectedRow
        if selectedIndex >= 0 {
            let desk = desks[selectedIndex]
            deskDetailViewController.desk = desk
            
            deskDetailBox.isHidden = false
            emptyStateBox.isHidden = true
        } else {
            deskDetailBox.isHidden = true
            emptyStateBox.isHidden = false
        }
    }
}

extension PreferencesViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateDeskDetail()
    }
    
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
            deskTableView.selectRowIndexes(IndexSet(integer: desks.count - 1), byExtendingSelection: false)
        }
        
        saveDesks()
    }
}
