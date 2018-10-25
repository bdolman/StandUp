//
//  Desk+CoreDataClass.swift
//  
//
//  Created by Ben Dolman on 10/24/18.
//
//

import Foundation
import CoreData

@objc(Desk)
public class Desk: NSManagedObject {
    @objc public enum Direction: Int32 {
        case stopped
        case up
        case down
    }
    
    @objc public enum ConnectionState: Int32 {
        case closed
        case connecting
        case open
    }
    
    var connectionError: Error?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(nextOrderValue(), forKey: "order")
    }
    
    private func nextOrderValue() -> Int32 {
        guard let context = managedObjectContext else { return 0 }
        
        let fetchRequest: NSFetchRequest<Desk> = Desk.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "SELF != %@", self)
        fetchRequest.sortDescriptors = [Desk.sortOrder(ascending: false)]
        let results = try! context.fetch(fetchRequest)
        if let lastOrder = results.first?.order {
            return lastOrder + 1
        } else {
            return 0
        }
    }
}

extension Desk {
    static func sortOrder(ascending: Bool) -> NSSortDescriptor {
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: ascending)
        return sortDescriptor
    }
}

extension Desk {
    var connectionStatusString: String {
        var statusString: String
        switch (connectionState, connectionError) {
        case (.connecting, _):
            statusString = "Connecting..."
        case (.open, _):
            statusString = "Connected"
        case (.closed, .some(let error)):
            statusString = "Error"
            if (error as NSError).domain == NSURLErrorDomain {
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    statusString = "Internet offline"
                }
            }
        case (.closed, .none):
            statusString = "Disconnected"
        }
        return statusString
    }
}
