//
//  Globals+CoreDataClass.swift
//  
//
//  Created by Ben Dolman on 10/24/18.
//
//

import Foundation
import CoreData

@objc(Globals)
public class Globals: NSManagedObject {
    public class func globalsIn(_ context: NSManagedObjectContext) -> Globals {
        // This caching works because NSManagedObject holds a weak ref to its context
        if let globals = context.userInfo["globalsObject"] as? Globals {
            return globals
        }
        let globals = ensureGlobalsIn(context)
        context.userInfo["globalsObject"] = globals
        return globals
    }
    
    private class func ensureGlobalsIn(_ context: NSManagedObjectContext) -> Globals {
         let fetchRequest: NSFetchRequest<Globals> = Globals.fetchRequest()
        if let globals = try! fetchRequest.execute().first {
            return globals
        } else {
            let globals = Globals(entity: Globals.entity(), insertInto: context)
            try! context.save()
            return globals
        }
    }
}
