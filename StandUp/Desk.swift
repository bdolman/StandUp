//
//  Desk.swift
//  StandUp
//
//  Created by Ben Dolman on 10/22/18.
//  Copyright © 2018 Hit Labs. All rights reserved.
//

import Foundation
import Alamofire

class Desk: NSObject, Codable {
    let deviceID: String
    @objc dynamic var accessToken: String {
        didSet {
            guard accessToken != oldValue else { return }
            if source != nil {
                startEventObserver()
            }
        }
    }
    @objc dynamic var name: String
    
    @objc dynamic var height: Int = 0
    
    @objc enum Direction: Int {
        case stopped
        case up
        case down
    }
    @objc dynamic var direction: Direction = .stopped
    
    @objc enum ConnectionState: Int {
        case connecting
        case open
        case closed
    }
    @objc dynamic var connectionState: ConnectionState = .closed
    
    var connectionError: Error?
    
    private var source: EventSource?
    
    private lazy var baseURL: URL = {
        let host = URL(string: "https://api.particle.io")!
        let base = host.appendingPathComponent("/v1/devices/\(self.deviceID)")
        return base
    }()
    
    private var headers: [String: String] {
        return [
            "Authorization" : "Bearer \(self.accessToken)"
        ]
    }
    
    static func == (lhs: Desk, rhs: Desk) -> Bool {
        return lhs.deviceID == rhs.deviceID
    }
    
    init(deviceID: String, accessToken: String, name: String) {
        self.deviceID = deviceID
        self.accessToken = accessToken
        self.name = name
        super.init()
        startEventObserver()
        updateHeight()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceID = try container.decode(String.self, forKey: .deviceID)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        name = try container.decode(String.self, forKey: .name)
        super.init()
        startEventObserver()
        updateHeight()
    }
    
    func close() {
        removeEventObserver()
    }
    
    override var debugDescription: String {
        return "\(name) (\(deviceID))"
    }
    
    // Codable
    private enum CodingKeys: String, CodingKey {
        case deviceID
        case accessToken
        case name
    }
}


extension Desk {
    private func removeEventObserver() {
        let oldSource = source
        source = nil
        oldSource?.close()
        
        connectionError = nil
        connectionState = .closed
        direction = .stopped
    }
    
    private func startEventObserver() {
        removeEventObserver()
        connectionState = .connecting

        let url = baseURL.appendingPathComponent("events")
        let newSource = EventSource(url: url, timeoutInterval: 30.0,
                             queue: DispatchQueue.main, accessToken: accessToken)
        source = newSource
        let handler: EventSourceEventHandler = {[weak self, weak newSource] (event: Event!) -> Void in
            guard self?.source == newSource else { return } // Source has changed
            self?.handleEvent(event)
        }
        newSource?.onOpen(handler)
        newSource?.onError(handler)
        newSource?.onMessage(handler)
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
                self.height = height
            }
        case .moveTimeout:
            direction = .stopped
        }
    }
    
    private func updateHeight() {
        getHeight { [weak self] (height, error) in
            if let newHeight = height, self?.height != newHeight {
                self?.height = newHeight
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
    
    func getHeight(_ completionHandler: @escaping (_ height: Int?, _ error: Error?) -> Void) {
        let url = self.baseURL.appendingPathComponent("getHeight")
        _ = Alamofire.request(url, method: .post, headers: headers)
            .responseObject { (response: DataResponse<GetHeightResponse>) in
                switch response.result {
                case .success(let response):
                    completionHandler(response.height, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
        }
    }
}

private final class GetHeightResponse: ResponseObjectSerializable {
    let height: Int
    init?(response: HTTPURLResponse, representation: Any) {
        if let height = (representation as AnyObject).value(forKeyPath: "return_value") as? Int {
            self.height = height
        } else {
            height = 0
            return nil
        }
    }
}

private enum DeskEvent {
    case movingDown
    case movingUp
    case targetReached
    case height(Int)
    case moveTimeout
    
    init?(sparkEvent: SparkEvent) {
        switch sparkEvent.event {
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
