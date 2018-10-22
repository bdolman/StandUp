//
//  Device.swift
//  StandUp
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

import Foundation
import Alamofire

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

class DeviceOld {
    lazy var baseURL: URL = {
        let host = URL(string: "https://api.particle.io")!
        let base = host.appendingPathComponent("/v1/devices/\(self.deviceId)")
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
