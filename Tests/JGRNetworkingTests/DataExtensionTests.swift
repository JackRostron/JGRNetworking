//
//  DataExtensionTests.swift
//  
//
//  Created by Jack Rostron on 02/08/2023.
//

import XCTest
@testable import JGRNetworking

class DataExtensionTests: XCTestCase {
    
    func testAppendString() {
        // Given
        var data = Data()
        let string = "Test string"
        
        // When
        data.append(string)
        
        // Then
        let returnedString = String(data: data, encoding: .utf8)
        XCTAssertEqual(returnedString, string)
    }
}
