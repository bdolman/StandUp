//
//  Request.swift
//  GeekDesk
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

import Foundation
import Alamofire

public protocol ResponseObjectSerializable {
    init?(response: HTTPURLResponse, representation: Any)
}

extension DataRequest {
    public func responseObject<T: ResponseObjectSerializable>(_ completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        let responseSerializer = DataResponseSerializer<T> { request, response, data, error in
            guard error == nil else { return .failure(error!) }
            
            let JSONResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = JSONResponseSerializer.serializeResponse(request, response, data, error)
            
            switch result {
            case .success(let value):
                if let
                    response = response,
                    let responseObject = T(response: response, representation: value)
                {
                    return .success(responseObject)
                } else {
                    let failureReason = "JSON could not be serialized into response object: \(value)"
                    let error = NSError(domain: "GeekDesk", code: 1, userInfo: [
                        NSLocalizedDescriptionKey : failureReason
                    ])
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}
