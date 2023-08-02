//
//  EncodableExtensionsTests.swift
//  
//
//  Created by Jack Rostron on 02/08/2023.
//

import XCTest

// MARK: - Tests

class EncodableExtensionsTests: XCTestCase {
    func testAsDictionary() throws {
        let testModel = TestModel(name: "Test", age: 123)
        
        let dictionary = try testModel.asDictionary()
        
        XCTAssertEqual(dictionary["name"] as? String, "Test")
        XCTAssertEqual(dictionary["age"] as? Int, 123)
    }
    
    func testAsJSONString() {
        let testModel = TestModel(name: "Test", age: 123)
        
        let jsonString = testModel.asJSONString()
        
        XCTAssertNotNil(jsonString)
        
        // Expected output: "{"name":"Test","age":123}"
        // The order of properties can vary, so we check if both properties are included
        XCTAssertTrue(jsonString!.contains("\"name\":\"Test\""))
        XCTAssertTrue(jsonString!.contains("\"age\":123"))
    }
    
    func testAsDictionaryWithFailure() {
        let faultyModel = FaultyModel(name: "Test", age: nil)
        
        XCTAssertThrowsError(try faultyModel.asDictionary()) { error in
            // Here, you can also test the type of error, its properties, etc.
            XCTAssertTrue(error is EncodingError)
        }
    }
    
    func testAsJSONStringWithFailure() {
        let faultyModel = FaultyModel(name: "Test", age: nil)
        
        let jsonString = faultyModel.asJSONString()
        
        // Because our method `asJSONString` handles encoding errors internally and returns nil, we expect a nil result
        XCTAssertNil(jsonString)
    }
    
    func testAsJSONStringWithEmptyDictionary() {
        struct EmptyModel: Encodable {}
        let emptyModel = EmptyModel()
        
        let jsonString = emptyModel.asJSONString()
        
        // An empty model should still result in a valid (but empty) JSON object string
        XCTAssertEqual(jsonString, "{}")
    }
    
    func testEncodingComplexObject() throws {
        struct ComplexModel: Encodable {
            struct NestedModel: Encodable {
                let value: Int
            }
            let nestedModel: NestedModel
            let array: [Int]
        }
        let complexModel = ComplexModel(nestedModel: .init(value: 123), array: [1, 2, 3])
        
        let dictionary = try complexModel.asDictionary()
        let nestedModelDict = dictionary["nestedModel"] as? [String: Any]
        let array = dictionary["array"] as? [Int]
        
        XCTAssertEqual(nestedModelDict?["value"] as? Int, 123)
        XCTAssertEqual(array, [1, 2, 3])
    }
    
    func testDecodingResult() throws {
        struct Model: Codable {
            let name: String
            let age: Int
        }
        let model = Model(name: "Test", age: 123)
        
        let jsonString = model.asJSONString()
        XCTAssertNotNil(jsonString)
        
        let data = jsonString!.data(using: .utf8)!
        let decodedModel = try JSONDecoder().decode(Model.self, from: data)
        
        XCTAssertEqual(decodedModel.name, model.name)
        XCTAssertEqual(decodedModel.age, model.age)
    }
}

// MARK: - Supporting Test Models

struct TestModel: Encodable {
    let name: String
    let age: Int
}

struct FaultyModel: Encodable {
    let name: String
    var age: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, age
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        if let age = age {
            try container.encode(age, forKey: .age)
        } else {
            // Force an encoding failure
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Invalid value"))
        }
    }
}
