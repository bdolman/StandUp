//
//  Desk.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Foundation

let DeskHeightChangedNotification = "DeskHeightChangedNotification"
let DeskStateChangedNotification = "DeskStateChangedNotification"

enum DeskState {
    case Lowered
    case Lowering
    case Raised
    case Raising
}

private enum DeskEvent {
    case MovingDown
    case MovingUp
    case TargetReached
    case Height(Int)
    case MoveTimeout
    
    init?(sparkEvent: SparkEvent) {
        switch sparkEvent.event {
        case "movingdown":
            self = .MovingDown
        case "movingup":
            self = .MovingUp
        case "height":
            if let heightValue = Int(sparkEvent.data) {
                self = .Height(heightValue)
            } else {
                return nil
            }
        case "targetreached":
            self = .TargetReached
        case "movetimeout":
            self = .MoveTimeout
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
    private var source: EventSource!
    
    let lock = NSRecursiveLock()
    
    var state: DeskState? = nil {
        didSet(oldValue) {
            guard oldValue != state else { return }
            NSNotificationCenter.defaultCenter().postNotificationName(DeskStateChangedNotification, object: self)
        }
    }
    var height: Int? = nil {
        didSet(oldValue) {
            guard oldValue != height else { return }
            NSNotificationCenter.defaultCenter().postNotificationName(DeskHeightChangedNotification, object: self)
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
    
    private func handleDeskEvent(event: DeskEvent) {
        NSLog("\(event)")
        switch event {
        case .MovingDown:
            state = .Lowering
        case .MovingUp:
            state = .Raising
        case .TargetReached where state == .Lowering:
            state = .Lowered
            self.updateCurrentState()
        case .TargetReached where state == .Raising:
            state = .Raised
            self.updateCurrentState()
        case .Height(let height):
            self.height = height
        case .MoveTimeout:
            self.updateCurrentState()
        default: break
        }
    }
    
    private func handleSparkEvent(event: SparkEvent) {
        if let deskEvent = DeskEvent(sparkEvent: event) {
            handleDeskEvent(deskEvent)
        }
    }
    
    private func setupEventObserver() {
        let url = device.baseURL.URLByAppendingPathComponent("events")
        source = EventSource(URL: url, timeoutInterval: 30.0,
            queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), accessToken: device.accessToken)
        let handler: EventSourceEventHandler = {[unowned self] (event: Event!) -> Void in
            guard let data = event.data else {
                NSLog("Event error \(event.error)")
                return
            }
            do {
                let obj = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                guard var dict = obj as? [String:AnyObject] else {
                    NSLog("Invalid event data")
                    return
                }
                if let eventName = event.name {
                    dict["event"] = eventName
                }
                let sparkEvent = SparkEvent(eventDict: dict)
                self.handleSparkEvent(sparkEvent)
            } catch {
                NSLog("Event parse error \(error)")
            }
        }
        source.onMessage(handler)
    }
    
    private func updateStateWithHeight(height: Int) {
        let midpoint = sittingHeight + ((standingHeight - sittingHeight) / 2)
        state = height <= midpoint ? .Lowered : .Raised
    }
    
    private func updateStateToMatchCurrentHeight() {
        if let height = self.height {
            updateStateWithHeight(height)
        }
    }
    
    func updateCurrentState() {
        device.getHeight { (height, error) -> Void in
            if let height = height {
                self.updateStateWithHeight(height)
                self.height = height
            } else {
                NSLog("getHeight error \(error)")
            }
        }
    }
    
    func raise() {
        if state != .Raised {
            device.setHeight(standingHeight) { error in
                if let error = error {
                    NSLog("setHeight error \(error)")
                }
            }
        }
    }
    
    func lower() {
        if state != .Lowered {
            device.setHeight(sittingHeight) { error in
                if let error = error {
                    NSLog("setHeight error \(error)")
                }
            }
        }
    }
}