//
//  Desk+CoreDataClass.swift
//  
//
//  Created by Ben Dolman on 10/24/18.
//
//

import Foundation
import CoreData
import Alamofire

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
    
    private var source: EventSource?
    
    var orderedPresets: [Preset] {
        return presets.sorted(by: {$0.order < $1.order})
    }
    
    var heightOrderedPresets: [Preset] {
        return presets.sorted(by: {$0.height < $1.height})
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(nextOrderValue(), forKey: "order")
        if let context = managedObjectContext {
            Desk.ensureActiveDesk(inContext: context)
        }
        setInitialPresets()
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        if Thread.current.isMainThread, source == nil {
            startEventObserver()
        }
    }
    
    public override func didSave() {
        super.didSave()
        if Thread.current.isMainThread, !isDeleted, source == nil {
            startEventObserver()
        }
    }
    
    public override func willSave() {
        super.willSave()
        if Thread.current.isMainThread,
            changedValues().keys.contains("accessToken") ||  changedValues().keys.contains("deviceID"),
            source != nil
        {
            stopEventObserver()
        }
    }
    
    public override func prepareForDeletion() {
        super.prepareForDeletion()
        if Thread.current.isMainThread {
            stopEventObserver()
        }
        if let context = managedObjectContext {
            Desk.ensureActiveDesk(inContext: context)
        }
    }
    
    private func setInitialPresets() {
        guard let context = managedObjectContext else { return }
        
        let sitPreset = Preset(context: context)
        sitPreset.order = 0
        sitPreset.height = 60
        sitPreset.name = "Sit"
        
        let standPreset = Preset(context: context)
        standPreset.order = 1
        standPreset.height = 100
        standPreset.name = "Stand"
        
        let initialPresets = Set([sitPreset, standPreset])
        initialPresets.forEach({$0.setPrimitiveValue(self, forKey: "desk")})
        setPrimitiveValue(initialPresets, forKey: "presets")
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
        switch (connectionState, isOnline, connectionError) {
        case (.connecting, _, _):
            statusString = "Connecting..."
        case (.open, true, _):
            statusString = "Connected"
        case (.open, false, _):
            statusString = "Desk offline"
        case (.closed, _, .some(let error)):
            statusString = "Error"
            if (error as NSError).domain == NSURLErrorDomain {
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    statusString = "Internet offline"
                }
            }
        case (.closed, _, .none):
            statusString = "Disconnected"
        }
        return statusString
    }
}

// MARK: - Network model
extension Desk {
    private var baseURL: URL {
        let host = URL(string: "https://api.particle.io")!
        let base = host.appendingPathComponent("/v1/devices/\(self.deviceID)")
        return base
    }
    
    private var headers: [String: String] {
        return [
            "Authorization" : "Bearer \(self.accessToken)"
        ]
    }
    
    private func stopEventObserver() {
        let oldSource = source
        source = nil
        oldSource?.close()
        
        connectionError = nil
        connectionState = .closed
        direction = .stopped
    }
    
    private func startEventObserver() {
        stopEventObserver()
        connectionState = .connecting
        
        let url = baseURL.appendingPathComponent("events")
        let newSource = EventSource(url: url, timeoutInterval: 10.0,
                                    queue: DispatchQueue.global(qos: .background), accessToken: accessToken)
        source = newSource
        let handler: EventSourceEventHandler = {[weak self, weak newSource] (event: Event!) -> Void in
            DispatchQueue.main.async {
                guard self?.source == newSource else { return } // Source has changed
                self?.handleEvent(event)
            }
        }
        newSource?.onOpen({ [weak self] (event) in
            handler(event)
            DispatchQueue.main.async {
                self?.updateHeight()
            }
        })
        newSource?.onError(handler)
        newSource?.onMessage(handler)
        
        updateHeight()
    }
    
    private func handleEvent(_ event: Event) {
        updateConnectionState(fromEventState: event.readyState, error: event.error)
        
        guard let data = event.data else {
            if let error = event.error {
                NSLog("Event error \(error)")
            }
            return
        }
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            guard var dict = obj as? [String:AnyObject] else {
                NSLog("Invalid event data")
                return
            }
            if let eventName = event.name {
                dict["event"] = eventName as AnyObject
            }
            if let sparkEvent = SparkEvent(eventDict: dict) {
                handleSparkEvent(sparkEvent)
            }
        } catch {
            NSLog("Event parse error \(error)")
        }
    }
    
    private func updateConnectionState(fromEventState eventState: EventState, error: Error?) {
        let newState: ConnectionState
        var newError: Error?
        
        switch eventState {
        case kEventStateConnecting:
            newState = .connecting
        case kEventStateOpen:
            newState = .open
        default:
            newError = error
            newState = .closed
        }
        if newError as NSError? != connectionError as NSError? {
            connectionError = newError
        }
        if newState != connectionState {
            connectionState = newState
        }
    }
    
    private func handleSparkEvent(_ event: SparkEvent) {
        if let deskEvent = DeskEvent(sparkEvent: event) {
            handleDeskEvent(deskEvent)
        }
    }
    
    private func handleDeskEvent(_ event: DeskEvent) {
        // NSLog("\(event)")
        
        var newDirection: Direction?
        var newHeight: Int32?
        var newIsOnline: Bool?
        
        switch event {
        case .movingDown:
            newDirection = .down
        case .movingUp:
            newDirection = .up
        case .targetReached:
            newDirection = .stopped
        case .height(let height):
            newHeight = Int32(height)
        case .moveTimeout:
            newDirection = .stopped
        case .deviceStatus(let isOnline):
            newIsOnline = isOnline
        }
        
        if let direction = newDirection, self.direction != direction {
            self.direction = direction
        }
        if let height = newHeight, self.height != height {
            self.height = height
        }
        if let isOnline = newIsOnline, self.isOnline != isOnline {
            self.isOnline = isOnline
        }
    }
    
    private func updateHeight() {
        getHeight { [weak self] (height, isOnline, error) in
            if let newHeight = height, self?.height != Int32(newHeight) {
                self?.height = Int32(newHeight)
            }
            if let newIsOnline = isOnline, self?.isOnline != newIsOnline {
                self?.isOnline = newIsOnline
            }
        }
    }
}

// MARK: - Desk API calls
extension Desk {
    func setHeight(_ heightInCms: Int, completionHandler: @escaping (_ error: Error?) -> Void) {
        let url = self.baseURL.appendingPathComponent("setHeight")
        let params = ["arg" : heightInCms]
        Alamofire
            .request(url, method: .post, parameters: params, headers: headers)
            .response { (response) in
                completionHandler(response.error)
        }
    }
    
    func getHeight(_ completionHandler: @escaping (_ height: Int?, _ isOnline: Bool?, _ error: Error?) -> Void) {
        let url = self.baseURL.appendingPathComponent("getHeight")
        _ = Alamofire.request(url, method: .post, headers: headers)
            .responseObject { (response: DataResponse<GetHeightResponse>) in
                switch response.result {
                case .success(let response):
                    completionHandler(response.height, response.isOnline, nil)
                case .failure(let error):
                    completionHandler(nil, nil, error)
                }
        }
    }
}

// MARK: - Active desk
extension Desk {
    class func ensureActiveDesk(inContext context: NSManagedObjectContext) {
        let globals = Globals.globalsIn(context)
        if globals.activeDesk == nil || globals.activeDesk?.isDeleted == true {
            let fetchRequest: NSFetchRequest<Desk> = Desk.fetchRequest()
            fetchRequest.sortDescriptors = [Desk.sortOrder(ascending: true)]
            if let firstDesk = try? context.fetch(fetchRequest).first(where: {!$0.isDeleted}) {
                globals.activeDesk = firstDesk
            }
        }
    }
}


private final class GetHeightResponse: ResponseObjectSerializable {
    let height: Int
    let isOnline: Bool
    init?(response: HTTPURLResponse, representation: Any) {
        guard
            let height = (representation as AnyObject).value(forKeyPath: "return_value") as? Int,
            let isOnline = (representation as AnyObject).value(forKeyPath: "connected") as? Bool
        else {
            return nil
        }
        self.height = height
        self.isOnline = isOnline
    }
}

private enum DeskEvent {
    case deviceStatus(Bool)
    case movingDown
    case movingUp
    case targetReached
    case height(Int)
    case moveTimeout
    
    init?(sparkEvent: SparkEvent) {
        switch sparkEvent.event {
        case "spark/status" where sparkEvent.data == "online":
            self = .deviceStatus(true)
        case "spark/status" where sparkEvent.data == "offline":
            self = .deviceStatus(false)
        case "movingdown":
            self = .movingDown
        case "movingup":
            self = .movingUp
        case "height":
            if let heightValue = Int(sparkEvent.data) {
                self = .height(heightValue)
            } else {
                return nil
            }
        case "targetreached":
            self = .targetReached
        case "movetimeout":
            self = .moveTimeout
        default:
            return nil
        }
    }
}
