//
//  Device.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Foundation
import Alamofire

private final class GetHeightResponse: ResponseObjectSerializable {
    let height: Int
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        if let height = representation.valueForKeyPath("return_value") as? Int {
            self.height = height
        } else {
            height = 0
            return nil
        }
    }
}

class Device {
    lazy var baseURL: NSURL = {
        let host = NSURL(string: "https://api.particle.io")!
        let base = host.URLByAppendingPathComponent("/v1/devices/\(self.deviceId)")
        return base
    }()
    lazy var headers: [String: String] = {
        return [
            "Authorization" : "Bearer \(self.accessToken)"
        ]
    }()
    let accessToken: String
    let deviceId: String
    
    init(accessToken: String, deviceId: String) {
        self.accessToken = accessToken
        self.deviceId = deviceId
    }
    
    func setHeight(heightInCms: Int, completionHandler: (error: NSError?) -> Void) {
        let url = self.baseURL.URLByAppendingPathComponent("setHeight")
        let params = ["arg" : heightInCms]
        Alamofire.request(.POST, url, parameters: params, headers: headers)
            .response { request, response, data, error in
                completionHandler(error: error)
            }
    }
    
    func getHeight(completionHandler: (height: Int?, error: NSError?) -> Void) {
        let url = self.baseURL.URLByAppendingPathComponent("getHeight")
        Alamofire.request(.POST, url, headers: headers)
            .responseObject { (response: Response<GetHeightResponse, NSError>) in
                switch response.result {
                case .Success(let response):
                    completionHandler(height: response.height, error: nil)
                case .Failure(let error):
                    completionHandler(height: nil, error: error)
                }
            }
    }
}