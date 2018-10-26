//
//  PreferencesDeskDetailViewController.swift
//  StandUp
//
//  Created by Ben Dolman on 10/18/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa

class PreferencesDeskDetailViewController: NSViewController {
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var statusField: NSTextField!
    @IBOutlet weak var heightField: NSTextField!
    @IBOutlet weak var presetsTableView: NSTableView!
    
    var desk: Desk? {
        didSet {
            guard oldValue != desk else { return }
            updateDeskObservers()
            reloadData()
        }
    }
    
    private var observers = [NSKeyValueObservation]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    private func updateDeskObservers() {
        observers.removeAll()
        guard let desk = desk else { return }
        
        let changeHandler = { [weak self] (desk: Desk, _: Any) -> Void in
            self?.reloadData()
        }
        
        observers.append(contentsOf: [
            desk.observe(\.name, changeHandler: changeHandler),
            desk.observe(\.height, changeHandler: changeHandler),
            desk.observe(\.connectionState, changeHandler: changeHandler),
            desk.observe(\.connectionError, changeHandler: changeHandler),
            desk.observe(\.isOnline, changeHandler: changeHandler)
        ])
    }
    
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
    
    private func reloadData() {
        updateName()
        updateStatus()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let deskConfigController = segue.destinationController as? DeskConfigurationViewController {
            deskConfigController.delegate = self
            deskConfigController.desk = desk
            deskConfigController.managedObjectContext = desk?.managedObjectContext
        }
    }
}

extension PreferencesDeskDetailViewController: DeskConfigurationViewControllerDelegate {
    func deskConfigurationViewController(_ controller: DeskConfigurationViewController, savedDesk: Desk) {
        dismiss(controller)
    }
}
