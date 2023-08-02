//
//  Endpoint.swift
//
//  Created by Jack Rostron on 03/04/2017.
//  Copyright © 2020 Jack Rostron. All rights reserved.
//

import Foundation

/// For parsing Codables to the format required for the endpoint
public enum EncodingType {
    case json
    case form
    case multipartForm([MultipartForm])
}

public struct Endpoint {
    var uri: String?
    var pattern: String?
    let httpMethods: [HTTPMethod]
    let encodingType: EncodingType
    
    public init(url: String? = nil, pattern: String? = nil, methods: [HTTPMethod] = [.get], type: EncodingType = .json) {
        self.uri = url
        self.pattern = pattern
        self.httpMethods = methods
        self.encodingType = type
    }

    internal func with(args: [String: String]?) -> Endpoint? {
        guard let urlPattern = pattern else {
            return nil // We cannot create an Endpoint with arguments if we don't have a pattern
        }

        guard let args = args else {
            return self
        }

        return Endpoint(url: mapValuesToURL(args, urlPattern), methods: httpMethods, type: encodingType)
    }

    internal func url(with args: [String: String]? = nil) -> String? {
        if let uri = uri {
            return uri // If we have a URI we aren't pattern matching, continue
        }

        guard let urlPattern = pattern, let args = args else {
            return nil // We cannot create an Endpoint with arguments if we don't have a pattern
        }

        return mapValuesToURL(args, urlPattern)
    }

    private func mapValuesToURL(_ values: [String: String], _ url: String) -> String {
        var result = url
        for (key, value) in values {
            let identifier = "<\(key)>"
            result = result.replacingOccurrences(of: identifier, with: value)
        }
        return result
    }
}
