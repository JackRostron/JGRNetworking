//
//  Data.swift
//  
//
//  Created by Jack Rostron on 02/08/2023.
//

import Foundation

public extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
