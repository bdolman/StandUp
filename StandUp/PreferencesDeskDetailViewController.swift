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
    
    var desk: DeskStatic? {
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
        
        observers.append(desk.observe(\.name, changeHandler: { [weak self] (desk, change) in
            self?.updateName()
        }))
        observers.append(desk.observe(\.height, changeHandler: { [weak self] (desk, change) in
            self?.updateStatus()
        }))
        observers.append(desk.observe(\.connectionState, changeHandler: { [weak self] (desk, change) in
            self?.updateStatus()
        }))
    }
    
    private func updateName() {
        guard let desk = desk else { return }
        nameField.stringValue = desk.name
    }
    
    private func updateStatus() {
        guard let desk = desk else { return }
        
        let statusString = desk.connectionStatusString
        var heightString: String = ""
        switch (desk.connectionState, desk.connectionError) {
        case (.open, _):
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
        }
    }
}

extension PreferencesDeskDetailViewController: DeskConfigurationViewControllerDelegate {
    func deskConfigurationViewController(_ controller: DeskConfigurationViewController, savedDesk: DeskStatic) {
        dismiss(controller)
    }
}
