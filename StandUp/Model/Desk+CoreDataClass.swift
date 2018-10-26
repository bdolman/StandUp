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
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(nextOrderValue(), forKey: "order")
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
        if Thread.current.isMainThread, changedValues().keys.contains("accessToken"), source != nil {
            stopEventObserver()
        }
    }
    
    public override func prepareForDeletion() {
        super.prepareForDeletion()
        if Thread.current.isMainThread {
            stopEventObserver()
        }
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
            statusString = "Device is offline"
        case (.closed, _, .some(let error)):
            statusString = "Error"
            if (error as NSError).domain == NSURLErrorDomain {
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    statusString = "No internet connection"
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
                                    queue: DispatchQueue.main, accessToken: accessToken)
        source = newSource
        let handler: EventSourceEventHandler = {[weak self, weak newSource] (event: Event!) -> Void in
            guard self?.source == newSource else { return } // Source has changed
            self?.handleEvent(event)
        }
        newSource?.onOpen({ [weak self] (event) in
            handler(event)
            self?.updateHeight()
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
        self.connectionError = newError
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
        NSLog("\(event)")
        switch event {
        case .movingDown:
            direction = .down
        case .movingUp:
            direction = .up
        case .targetReached:
            direction = .stopped
        case .height(let height):
            if self.height != height {
                self.height = Int32(height)
            }
        case .moveTimeout:
            direction = .stopped
        case .deviceStatus(let isOnline):
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
