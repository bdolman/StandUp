//
//  Desk+CoreDataProperties.swift
//  
//
//  Created by Ben Dolman on 10/24/18.
//
//

import Foundation
import CoreData


extension Desk {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Desk> {
        return NSFetchRequest<Desk>(entityName: "Desk")
    }

    @NSManaged public var accessToken: String
    @NSManaged public var deviceID: String
    @NSManaged public var name: String
    @NSManaged public var order: Int32
    @NSManaged public var height: Int32
    @NSManaged public var isOnline: Bool
    @NSManaged public var direction: Direction
    @NSManaged public var connectionState: ConnectionState

}
