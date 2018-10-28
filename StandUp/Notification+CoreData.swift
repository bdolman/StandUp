//
//  Notification+CoreData.swift
//  StandUp
//
//  Created by Ben Dolman on 10/28/18.
//  Copyright © 2018 Ben Dolman. All rights reserved.
//

import Foundation
import CoreData

public enum ChangeType {
    case noChange
    case inserted
    case updated
    case deleted
}

extension Notification {
    public func objectChangeType(_ object: NSManagedObject) -> ChangeType {
        guard name == NSNotification.Name.NSManagedObjectContextObjectsDidChange ||
            name == NSNotification.Name.NSManagedObjectContextDidSave
            else {
                return .noChange
        }
        if let inserted = userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> , inserted.contains(object) {
            return .inserted
        }
        if let updated = userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> , updated.contains(object) {
            return .updated
        }
        if let refreshed = userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> , refreshed.contains(object) {
            return .updated
        }
        if let deleted = userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> , deleted.contains(object) {
            return .deleted
        }
        return .noChange
    }
    
    public func containsChangeForClass<T: NSManagedObject>(_ managedObjectClass: T.Type, keys: [String]? = nil) -> Bool {
        let selectedKeys = keys ?? [
            NSInsertedObjectsKey,
            NSUpdatedObjectsKey,
            NSRefreshedObjectsKey,
            NSDeletedObjectsKey
        ]
        for key in selectedKeys {
            if let collection = userInfo?[key] as? Set<NSManagedObject> , collection.contains(where: {$0 is T}) {
                return true
            }
        }
        return false
    }
    
    public func changedObjects<T: NSManagedObject>(ofClass objectClass: T.Type, keys: [String]? = nil) -> Set<T> {
        let selectedKeys = keys ?? [
            NSInsertedObjectsKey,
            NSUpdatedObjectsKey,
            NSRefreshedObjectsKey,
            NSDeletedObjectsKey
        ]
        var resultSet = Set<T>()
        for key in selectedKeys {
            if let collection = userInfo?[key] as? Set<NSManagedObject> {
                resultSet.formUnion(collection.compactMap({$0 as? T}))
            }
        }
        return resultSet
    }
}
