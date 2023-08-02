//
//  MultipartFormTests.swift
//  
//
//  Created by Jack Rostron on 02/08/2023.
//

import XCTest
@testable import JGRNetworking

class MultipartFormTests: XCTestCase {

    func testMultipartFormInitialization() {
        // Given
        let data = "Test data".data(using: .utf8)!
        let fieldName = "testField"
        let fileName = "test.txt"
        let mimeType = "text/plain"

        // When
        let multipartForm = MultipartForm(data: data, fieldName: fieldName, fileName: fileName, mimeType: mimeType)

        // Then
        XCTAssertEqual(multipartForm.data, data)
        XCTAssertEqual(multipartForm.fieldName, fieldName)
        XCTAssertEqual(multipartForm.fileName, fileName)
        XCTAssertEqual(multipartForm.mimeType, mimeType)
    }
}
