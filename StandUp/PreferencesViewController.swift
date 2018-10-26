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
    var managedObjectContext: NSManagedObjectContext!
    var settings: Settings!
    
    @IBOutlet weak var deskTableView: NSTableView!
    @IBOutlet weak var emptyStateBox: NSBox!
    @IBOutlet weak var deskDetailBox: NSBox!
    @IBOutlet weak var runAtLoginCheckbox: NSButton!
    
    private weak var deskDetailViewController: PreferencesDeskDetailViewController!
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Desk> = {
        let fetchRequest: NSFetchRequest<Desk> = Desk.fetchRequest()
        fetchRequest.sortDescriptors = [Desk.sortOrder(ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: self.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deskTableView.registerForDraggedTypes([DragDropType])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        deskTableView.delegate = self
        deskTableView.dataSource = self
        loadDesks()
        updateRunAtLoginCheckbox()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let deskConfigController = segue.destinationController as? DeskConfigurationViewController {
            deskConfigController.managedObjectContext = managedObjectContext
            deskConfigController.delegate = self
        }
        if let deskDetailController = segue.destinationController as? PreferencesDeskDetailViewController {
            deskDetailViewController = deskDetailController
        }
    }
    
    @IBAction func removeDeskButtonClicked(_ sender: Any) {
        guard let selectedIndexPath = deskTableView.selectedIndexPath else { return }
        let desk = fetchedResultsController.object(at: selectedIndexPath)
        managedObjectContext.delete(desk)
        try! managedObjectContext.save()
        
        
        if fetchedResultsController.fetchedObjects!.count > 0 {
            let newSelectedIndex = min(0, selectedIndexPath.item - 1)
            deskTableView.selectRowIndexes(IndexSet(integer: newSelectedIndex), byExtendingSelection: false)
        }
    }
    
    @IBAction func runAtLoginCheckboxChecked(_ sender: Any) {
        settings.enabledAtLogin = runAtLoginCheckbox.state == .on ? true : false
        LoginItemHelper.setLoginState(enabled: settings.enabledAtLogin)
    }
    
    private func updateRunAtLoginCheckbox() {
        runAtLoginCheckbox.state = settings.enabledAtLogin ? .on : .off
    }
    
    private func updateSelectedDesk() {
        if let selectedIndexPath = deskTableView.selectedIndexPath {
            let desk = fetchedResultsController.object(at: selectedIndexPath)
            deskDetailViewController.desk = desk
            
            deskDetailBox.isHidden = false
            emptyStateBox.isHidden = true
        } else {
            deskDetailViewController.desk = nil
            
            deskDetailBox.isHidden = true
            emptyStateBox.isHidden = false
        }
    }
    
    func selectDesk(desk: Desk) {
        if let selectedIndex = fetchedResultsController.indexPath(forObject: desk) {
            deskTableView.selectRowIndexes(IndexSet(integer: selectedIndex.item), byExtendingSelection: false)
        }
    }
}

// MARK: - Model management
extension PreferencesViewController {
    private func loadDesks() {
        deskTableView.reloadData()
        updateSelectedDesk()
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
            
            // Rearrange and then update ordering
            var desks = fetchedResultsController.fetchedObjects!
            desks.insert(desks.remove(at: from), at: to)
            for (index, desk) in desks.enumerated() {
                let newOrder = Int32(index)
                if desk.order != newOrder {
                    desk.order = newOrder
                }
            }
            try! managedObjectContext.save()
        }
        
        return true
    }
}

// MARK: - NSTableViewDataSource
extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fetchedResultsController.sections![0].numberOfObjects
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let indexPath = IndexPath(item: row, section: 0)
        return fetchedResultsController.object(at: indexPath)
    }
}

extension PreferencesViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        deskTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        deskTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type {
        case .insert:
            let indexSet = IndexSet(integer: newIndexPath!.item)
            deskTableView.insertRows(at: indexSet, withAnimation: .slideDown)
        case .delete:
            let indexSet = IndexSet(integer: indexPath!.item)
            deskTableView.removeRows(at: indexSet, withAnimation: .effectFade)
        case .move where indexPath! == newIndexPath!: fallthrough // This happens, despite documentation saying it shouldn't
        case .update:
            let indexSet = IndexSet(integer: indexPath!.item)
            deskTableView.reloadData(forRowIndexes: indexSet, columnIndexes: IndexSet(integer: 0))
        case .move:
            deskTableView.moveRow(at: indexPath!.item, to: newIndexPath!.item)
        }
    }
}

extension PreferencesViewController: DeskConfigurationViewControllerDelegate {
    func deskConfigurationViewController(_ controller: DeskConfigurationViewController, savedDesk: Desk) {
        dismiss(controller)
        if let selectedIndex = fetchedResultsController.indexPath(forObject: savedDesk) {
            deskTableView.selectRowIndexes(IndexSet(integer: selectedIndex.item), byExtendingSelection: false)
        }
    }
}


extension NSTableView {
    var selectedIndexPath: IndexPath? {
        guard selectedRow >= 0 else { return nil }
        return IndexPath(item: selectedRow, section: 0)
    }
}
