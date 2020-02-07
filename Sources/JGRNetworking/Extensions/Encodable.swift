//
//  EncodableExtension.swift
//
//  Created by Jack Rostron on 03/04/2017.
//  Copyright © 2020 Jack Rostron. All rights reserved.
//

import Foundation

public extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
    
    func asJSONString() -> String? {
        do {
            let data = try JSONEncoder().encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
