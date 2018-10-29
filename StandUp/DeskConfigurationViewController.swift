//
//  DeskConfigurationViewController.swift
//  StandUp
//
//  Created by Ben Dolman on 10/18/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Cocoa

protocol DeskConfigurationViewControllerDelegate: NSObjectProtocol {
    func deskConfigurationViewController(_ controller: DeskConfigurationViewController, savedDesk: Desk)
}

class DeskConfigurationViewController: NSViewController {
    // Injected properties
    var managedObjectContext: NSManagedObjectContext!
    var desk: Desk?
    
    weak var delegate: DeskConfigurationViewControllerDelegate?
    
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var accessTokenField: NSTextField!
    @IBOutlet weak var deviceIDField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadData()
        validateData()
    }
    
    private var name: String {
        get {
            return nameField.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        set {
            nameField.stringValue = newValue
        }
    }
    
    private var accessToken: String {
        get {
            return accessTokenField.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        set {
            accessTokenField.stringValue = newValue
        }
    }
    
    private var deviceID: String {
        get {
            return deviceIDField.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        set {
            deviceIDField.stringValue = newValue
        }
    }
    
    private func reloadData() {
        name = desk?.name ?? ""
        accessToken = desk?.accessToken ?? ""
        deviceID = desk?.deviceID ?? ""
    }
    
    @IBAction private func saveButtonClicked(_ sender: Any) {
        let savedDesk = desk ?? Desk(context: managedObjectContext)
        if savedDesk.deviceID != deviceID {
            savedDesk.deviceID = deviceID
        }
        if savedDesk.name != name {
            savedDesk.name = name
        }
        if savedDesk.accessToken != accessToken {
            savedDesk.accessToken = accessToken
        }
        try! managedObjectContext.save()
        delegate?.deskConfigurationViewController(self, savedDesk: savedDesk)
    }
    
}

// MARK: - Validation
extension DeskConfigurationViewController {
    private var isDataValid: Bool {
        let isValid = !name.isEmpty && !accessToken.isEmpty && !deviceID.isEmpty
        return isValid
    }
    
    private func validateData() {
        saveButton.isEnabled = isDataValid
    }
}

// MARK: - NSTextFieldDelegate
extension DeskConfigurationViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        validateData()
    }
}
