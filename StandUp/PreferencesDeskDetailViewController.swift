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
            reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    private func reloadData() {
        guard let desk = desk else { return }
        nameField.stringValue = desk.name
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let deskConfigController = segue.destinationController as? DeskConfigurationViewController {
            deskConfigController.delegate = self
            deskConfigController.desk = desk
        }
    }
}

extension PreferencesDeskDetailViewController: DeskConfigurationViewControllerDelegate {
    func deskConfigurationViewController(_ controller: DeskConfigurationViewController, savedDesk: Desk) {
        dismiss(controller)
        reloadData()
    }
}
