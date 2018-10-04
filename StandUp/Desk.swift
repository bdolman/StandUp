//
//  Desk.swift
//  StandUp
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Foundation

let DeskHeightChangedNotification = "DeskHeightChangedNotification"
let DeskStateChangedNotification = "DeskStateChangedNotification"

enum DeskState {
    case lowered
    case lowering
    case raised
    case raising
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

class Desk: NSObject {
    let device: Device
    
    var sittingHeight: Int {
        didSet(oldValue) {
            guard oldValue != sittingHeight else { return }
            updateStateToMatchCurrentHeight()
        }
    }
    var standingHeight: Int {
        didSet(oldValue) {
            guard oldValue != standingHeight else { return }
            updateStateToMatchCurrentHeight()
        }
    }
    fileprivate var source: EventSource!
    
    var pollForHeightChanges: Bool = false {
        didSet(oldValue) {
            guard oldValue != pollForHeightChanges else { return }
            if pollForHeightChanges {
                beginPollingForHeightChanges()
            } else {
                stopPollingForHeightChanges()
            }
        }
    }
    
    var pollingTimer: Timer?
    fileprivate func beginPollingForHeightChanges() {
        DispatchQueue.main.async {
            self.pollingTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                selector: #selector(Desk.pollingTimerFired(_:)), userInfo: nil, repeats: false)
        }
    }
    
    fileprivate func stopPollingForHeightChanges() {
        DispatchQueue.main.async {
            self.pollingTimer?.invalidate()
            self.pollingTimer = nil
        }
    }
    
    @objc fileprivate func pollingTimerFired(_ timer: Timer) {
        device.getHeight { (height, error) -> Void in
            if let height = height {
                self.height = height
            } else if let error = error {
                NSLog("getHeight error \(error)")
            }
            if self.pollForHeightChanges {
                self.beginPollingForHeightChanges()
            }
        }
    }
    
    var state: DeskState? = nil {
        didSet(oldValue) {
            guard oldValue != state else { return }
            NotificationCenter.default.post(name: Notification.Name(rawValue: DeskStateChangedNotification), object: self)
        }
    }
    var height: Int? = nil {
        didSet(oldValue) {
            guard oldValue != height else { return }
            NotificationCenter.default.post(name: Notification.Name(rawValue: DeskHeightChangedNotification), object: self)
        }
    }
    
    init(device: Device, sittingHeight: Int, standingHeight: Int) {
        self.device = device
        self.sittingHeight = sittingHeight
        self.standingHeight = standingHeight
        super.init()
        setupEventObserver()
    }
    
    deinit {
        source.close()
    }
    
    fileprivate func handleDeskEvent(_ event: DeskEvent) {
        NSLog("\(event)")
        switch event {
        case .movingDown:
            state = .lowering
        case .movingUp:
            state = .raising
        case .targetReached where state == .lowering:
            state = .lowered
            self.updateCurrentState()
        case .targetReached where state == .raising:
            state = .raised
            self.updateCurrentState()
        case .height(let height):
            self.height = height
        case .moveTimeout:
            self.updateCurrentState()
        default: break
        }
    }
    
    fileprivate func handleSparkEvent(_ event: SparkEvent) {
        if let deskEvent = DeskEvent(sparkEvent: event) {
            handleDeskEvent(deskEvent)
        }
    }
    
    fileprivate func setupEventObserver() {
        let url = device.baseURL.appendingPathComponent("events")
        
        source = EventSource(url: url, timeoutInterval: 30.0,
            queue: DispatchQueue.global(qos: .background), accessToken: device.accessToken)
        let handler: EventSourceEventHandler = {[unowned self] (event: Event!) -> Void in
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
                let sparkEvent = SparkEvent(eventDict: dict)
                self.handleSparkEvent(sparkEvent!)
            } catch {
                NSLog("Event parse error \(error)")
            }
        }
        source.onMessage(handler)
    }
    
    fileprivate func updateStateWithHeight(_ height: Int) {
        let midpoint = sittingHeight + ((standingHeight - sittingHeight) / 2)
        state = height <= midpoint ? .lowered : .raised
    }
    
    fileprivate func updateStateToMatchCurrentHeight() {
        if let height = self.height {
            updateStateWithHeight(height)
        }
    }
    
    func updateCurrentState() {
        device.getHeight { (height, error) -> Void in
            if let height = height {
                self.updateStateWithHeight(height)
                self.height = height
            } else if let error = error {
                NSLog("getHeight error \(error)")
            }
        }
    }
    
    func raise() {
        if state != .raised {
            device.setHeight(standingHeight) { error in
                if let error = error {
                    NSLog("setHeight error \(error)")
                }
            }
        }
    }
    
    func lower() {
        if state != .lowered {
            device.setHeight(sittingHeight) { error in
                if let error = error {
                    NSLog("setHeight error \(error)")
                }
            }
        }
    }
}
