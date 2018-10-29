//
//  PreferencesDeskDetailViewController.swift
//  StandUp
//
//  Created by Ben Dolman on 10/18/18.
//  Copyright © 2018 Ben Dolman. All rights reserved.
//

import Cocoa

private var DragDropType = NSPasteboard.PasteboardType(rawValue: "private.table-row")

private enum Column: String {
    case number
    case name
    case height
}

class PreferencesDeskDetailViewController: NSViewController {
    // Injected properties
    var managedObjectContext: NSManagedObjectContext!
    var desk: Desk? {
        didSet {
            guard oldValue != desk else { return }
            updateDeskObservers()
            reloadDeskData()
            reloadPresetsData()
        }
    }
    
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var statusField: NSTextField!
    @IBOutlet weak var heightField: NSTextField!
    @IBOutlet weak var presetsTableView: NSTableView!
    
    private var observers = [NSKeyValueObservation]()
    private var presetsFetchedResultsController: NSFetchedResultsController<Preset>?

    override func viewDidLoad() {
        super.viewDidLoad()
        presetsTableView.registerForDraggedTypes([DragDropType])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        presetsTableView.dataSource = self
        presetsTableView.delegate = self
        reloadDeskData()
        reloadPresetsData()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let deskConfigController = segue.destinationController as? DeskConfigurationViewController {
            deskConfigController.delegate = self
            deskConfigController.desk = desk
            deskConfigController.managedObjectContext = desk?.managedObjectContext
        }
    }
}

// MARK: - Desk properties
extension PreferencesDeskDetailViewController {
    private func updateName() {
        guard let desk = desk else { return }
        nameField.stringValue = desk.name
    }
    
    private func updateStatus() {
        guard let desk = desk else { return }
        
        let statusString = desk.connectionStatusString
        var heightString: String = ""
        switch (desk.connectionState, desk.isOnline) {
        case (.open, true):
            heightString = "\(desk.height) cm"
        default:
            break
        }
        
        statusField.stringValue = statusString
        heightField.stringValue = heightString
    }
    
    private func reloadDeskData() {
        updateName()
        updateStatus()
    }
}

// MARK: - Presets
extension PreferencesDeskDetailViewController {
    private func reloadPresetsData() {
        createPresetsFetchedResultsController()
        presetsTableView.reloadData()
    }
    
    @IBAction private func addPreset(_ sender: Any) {
        guard let desk = desk else { return }
        let preset = Preset(context: managedObjectContext)
        preset.desk = desk
        try! managedObjectContext.save()
    }
    
    @IBAction private func removePreset(_ sender: Any) {
        guard let presetsFetchedResultsController = presetsFetchedResultsController else { return }
        guard let selectedIndexPath = presetsTableView.selectedIndexPath else { return }
        let preset = presetsFetchedResultsController.object(at: selectedIndexPath)
        managedObjectContext.delete(preset)
        try! managedObjectContext.save()
    }
}

// MARK: - Desk setup
extension PreferencesDeskDetailViewController {
    private func createPresetsFetchedResultsController() {
        presetsFetchedResultsController?.delegate = nil
        presetsFetchedResultsController = nil
        guard let desk = desk else { return }
        let fetchRequest: NSFetchRequest<Preset> = Preset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "desk == %@", desk)
        fetchRequest.sortDescriptors = [Preset.sortOrder(ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: self.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        presetsFetchedResultsController = frc
        frc.delegate = self
        try! frc.performFetch()
    }
    
    private func updateDeskObservers() {
        observers.removeAll()
        guard let desk = desk else { return }
        
        let deskChangeHandler = { [weak self] (desk: Desk, _: Any) -> Void in
            self?.reloadDeskData()
        }
        
        observers.append(contentsOf: [
            desk.observe(\.name, changeHandler: deskChangeHandler),
            desk.observe(\.height, changeHandler: deskChangeHandler),
            desk.observe(\.connectionState, changeHandler: deskChangeHandler),
            desk.observe(\.connectionError, changeHandler: deskChangeHandler),
            desk.observe(\.isOnline, changeHandler: deskChangeHandler)
        ])
    }
}

// MARK: - NSTableViewDelegate
extension PreferencesDeskDetailViewController: NSTableViewDelegate {
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
        guard let presetsFetchedResultsController = presetsFetchedResultsController else { return false }
        
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
            var presets = presetsFetchedResultsController.fetchedObjects!
            presets.insert(presets.remove(at: from), at: to)
            for (index, presets) in presets.enumerated() {
                let newOrder = Int32(index)
                if presets.order != newOrder {
                    presets.order = newOrder
                }
            }
            try! managedObjectContext.save()
        }
        
        return true
    }
}

// MARK: - NSTableViewDataSource
extension PreferencesDeskDetailViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let presetsFetchedResultsController = presetsFetchedResultsController else { return 0 }
        return presetsFetchedResultsController.sections![0].numberOfObjects
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let presetsFetchedResultsController = presetsFetchedResultsController else { return nil }
        guard let columnIdentifier = tableColumn?.identifier.rawValue, let column = Column(rawValue: columnIdentifier) else { return nil }
        let indexPath = IndexPath(item: row, section: 0)
        let preset = presetsFetchedResultsController.object(at: indexPath)
        
        switch column {
        case .number:
            return row + 1
        case .name:
            if let name = preset.name, !name.isEmpty {
                return name
            } else {
                return "Preset #\(row + 1)"
            }
        case .height:
            return "\(preset.height) cm"
        }
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let presetsFetchedResultsController = presetsFetchedResultsController else { return }
        guard let columnIdentifier = tableColumn?.identifier.rawValue, let column = Column(rawValue: columnIdentifier) else { return }
        let indexPath = IndexPath(item: row, section: 0)
        let preset = presetsFetchedResultsController.object(at: indexPath)
        
        switch column {
        case .name:
            if let newName = object as? String, newName != preset.name {
                preset.name = newName
            }
        case .height:
            guard let heightString = object as? String else { break }
            guard let newHeight = heightString.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap({Int($0)})
                .first else { break }
            if preset.height != newHeight {
                preset.height = Int32(newHeight)
            }
        default:
            break
        }
        
        try! managedObjectContext.save()
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension PreferencesDeskDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        presetsTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        presetsTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type {
        case .insert:
            let indexSet = IndexSet(integer: newIndexPath!.item)
            presetsTableView.insertRows(at: indexSet, withAnimation: .slideDown)
        case .delete:
            let indexSet = IndexSet(integer: indexPath!.item)
            presetsTableView.removeRows(at: indexSet, withAnimation: .effectFade)
        case .move where indexPath! == newIndexPath!: fallthrough // This happens, despite documentation saying it shouldn't
        case .update:
            let indexSet = IndexSet(integer: indexPath!.item)
            presetsTableView.reloadData(forRowIndexes: indexSet, columnIndexes: IndexSet(integer: 0))
        case .move:
            presetsTableView.moveRow(at: indexPath!.item, to: newIndexPath!.item)
        }
    }
}

// MARK: - DeskConfigurationViewControllerDelegate
extension PreferencesDeskDetailViewController: DeskConfigurationViewControllerDelegate {
    func deskConfigurationViewController(_ controller: DeskConfigurationViewController, savedDesk: Desk) {
        dismiss(controller)
    }
}
