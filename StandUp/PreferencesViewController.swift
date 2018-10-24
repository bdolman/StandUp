//
//  PreferencesViewController.swift
//  StandUp
//
//  Created by Ben Dolman on 10/18/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa

private var DragDropType = NSPasteboard.PasteboardType(rawValue: "private.table-row")

class PreferencesViewController: NSViewController {
    // Injected properties
    var settings: Settings!
    
    @IBOutlet weak var deskTableView: NSTableView!
    @IBOutlet weak var emptyStateBox: NSBox!
    @IBOutlet weak var deskDetailBox: NSBox!
    @IBOutlet weak var runAtLoginCheckbox: NSButton!
    
    private weak var deskDetailViewController: PreferencesDeskDetailViewController!
    
    private var desks = [DeskStatic]()
    private var observers = [NSKeyValueObservation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deskTableView.registerForDraggedTypes([DragDropType])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        loadDesks()
        updateRunAtLoginCheckbox()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let deskConfigController = segue.destinationController as? DeskConfigurationViewController {
            deskConfigController.delegate = self
        }
        if let deskDetailController = segue.destinationController as? PreferencesDeskDetailViewController {
            deskDetailViewController = deskDetailController
        }
    }
    
    @IBAction func removeDeskButtonClicked(_ sender: Any) {
        let index = deskTableView.selectedRow
        guard index >= 0 else { return }
        remove(desk: desks[index])
    }
    
    @IBAction func runAtLoginCheckboxChecked(_ sender: Any) {
        settings.enabledAtLogin = runAtLoginCheckbox.state == .on ? true : false
        LoginItemHelper.setLoginState(enabled: settings.enabledAtLogin)
    }
    
    private func updateRunAtLoginCheckbox() {
        runAtLoginCheckbox.state = settings.enabledAtLogin ? .on : .off
    }
    
    private func updateSelectedDesk() {
        let selectedIndex = deskTableView.selectedRow
        if selectedIndex >= 0 {
            let desk = desks[selectedIndex]
            deskDetailViewController.desk = desk
            
            deskDetailBox.isHidden = false
            emptyStateBox.isHidden = true
        } else {
            deskDetailViewController.desk = nil
            
            deskDetailBox.isHidden = true
            emptyStateBox.isHidden = false
        }
    }
}

// MARK: - Model management
extension PreferencesViewController {
    private func loadDesks() {
        desks = settings.desks ?? []
        deskTableView.reloadData()
        updateSelectedDesk()
        updateDeskObservers()
    }
    
    private func saveDesks() {
        settings.desks = desks
    }
    
    private func updateDeskObservers() {
        observers.removeAll()
        desks.forEach { (desk) in
            observers.append(desk.observe(\.name, changeHandler: { [weak self] (desk, change) in
                self?.update(desk: desk)
                self?.saveDesks()
            }))
            observers.append(desk.observe(\.accessToken, changeHandler: { [weak self] (desk, change) in
                self?.update(desk: desk)
                self?.saveDesks()
            }))
            observers.append(desk.observe(\.height, changeHandler: { [weak self] (desk, change) in
                self?.update(desk: desk)
            }))
            observers.append(desk.observe(\.connectionState, changeHandler: { [weak self] (desk, change) in
                self?.update(desk: desk)
            }))
        }
    }
    
    private func update(desk: DeskStatic) {
        if let index = desks.firstIndex(of: desk), let cell = deskTableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? PreferencesDeskTableViewCell {
            cell.update(desk: desk)
        }
    }
    
    private func add(desk: DeskStatic, selectDesk: Bool) {
        desks.append(desk)
        deskTableView.insertRows(at: IndexSet(integer: desks.count - 1), withAnimation: .slideDown)
        if selectDesk {
            deskTableView.selectRowIndexes(IndexSet(integer: desks.count - 1), byExtendingSelection: false)
        }
        updateDeskObservers()
        saveDesks()
    }
    
    private func remove(desk: DeskStatic) {
        guard let index = desks.firstIndex(of: desk) else { return }
        
        desks.remove(at: index)
        deskTableView.removeRows(at: IndexSet([index]), withAnimation: .effectFade)
        
        if desks.count > 0 {
            let newSelectedIndex = max(0,index - 1)
            deskTableView.selectRowIndexes(IndexSet(integer: newSelectedIndex), byExtendingSelection: false)
        }
        
        updateDeskObservers()
        saveDesks()
        
        desk.close()
    }
    
    
}

// MARK: - NSTableViewDelegate
extension PreferencesViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateSelectedDesk()
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        
        let item = NSPasteboardItem()
        item.setString(String(row), forType: DragDropType)
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
            if let str = (dragItem.item as! NSPasteboardItem).string(forType: DragDropType), let index = Int(str) {
                oldIndexes.append(index)
            }
        }
        
        var oldIndexOffset = 0
        var newIndexOffset = 0

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

// MARK: - NSTableViewDataSource
extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return desks.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return desks[row]
    }
}

extension PreferencesViewController: DeskConfigurationViewControllerDelegate {
    func deskConfigurationViewController(_ controller: DeskConfigurationViewController, savedDesk: DeskStatic) {
        dismiss(controller)
        if !desks.contains(savedDesk) {
            add(desk: savedDesk, selectDesk: true)
        }
    }
}
