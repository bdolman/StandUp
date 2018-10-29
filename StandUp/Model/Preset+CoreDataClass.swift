//
//  Preset+CoreDataClass.swift
//  
//
//  Created by Ben Dolman on 10/27/18.
//
//

import Foundation
import CoreData

@objc(Preset)
public class Preset: NSManagedObject {
    
    public override func willSave() {
        super.willSave()
        if isInserted, desk != nil, order == -1 {
            order = nextOrderValue()
        }
    }
    
    private func nextOrderValue() -> Int32 {
        guard let context = managedObjectContext, let desk = desk else { return -1 }
        
        let fetchRequest: NSFetchRequest<Preset> = Preset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "desk == %@ AND SELF != %@", desk, self)
        fetchRequest.sortDescriptors = [Preset.sortOrder(ascending: false)]
        let results = try! context.fetch(fetchRequest)
        if let lastOrder = results.first?.order {
            return lastOrder + 1
        } else {
            return 0
        }
    }
    
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        if let index = desk?.orderedPresets.firstIndex(of: self) {
            return "Preset #\(index + 1)"
        }
        return "Preset"
    }
}

extension Preset {
    static func sortOrder(ascending: Bool) -> NSSortDescriptor {
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: ascending)
        return sortDescriptor
    }
}
