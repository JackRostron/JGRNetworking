//
//  EndpointTests.swift
//  
//
//  Created by Jack Rostron on 02/08/2023.
//

import XCTest
@testable import JGRNetworking

class EndpointTests: XCTestCase {
    func testURLWithArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let url = endpoint.url(with: ["id": "123"])
        XCTAssertEqual(url, "/users/123")
    }
    
    func testWithArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let newEndpoint = endpoint.with(args: ["id": "123"])
        XCTAssertEqual(newEndpoint?.uri, "/users/123")
    }
    
    func testWithMultipleArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>/posts/<postId>", methods: [.get])
        let url = endpoint.url(with: ["id": "123", "postId": "456"])
        XCTAssertEqual(url, "/users/123/posts/456")
    }
    
    func testWithoutArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let url = endpoint.url()
        XCTAssertNil(url)
    }
    
    func testWithArgsButNoPattern() {
        let endpoint = Endpoint(url: "/users/123", methods: [.get])
        let newEndpoint = endpoint.with(args: ["id": "456"])
        XCTAssertNil(newEndpoint)
    }
    
    func testNoMatchingArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let url = endpoint.url(with: ["username": "test"])
        XCTAssertEqual(url, "/users/<id>")
    }
    
    func testExtraArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let url = endpoint.url(with: ["id": "123", "username": "test"])
        XCTAssertEqual(url, "/users/123")
    }
    
    func testEmptyArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let url = endpoint.url(with: [:])
        XCTAssertEqual(url, "/users/<id>")
    }

    func testNilArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let newEndpoint = endpoint.with(args: nil)
        XCTAssertNotNil(newEndpoint)
        XCTAssertEqual(newEndpoint?.pattern, "/users/<id>")
        XCTAssertEqual(newEndpoint?.httpMethods, [.get])
    }
    
    func testEmptyPattern() {
        let endpoint = Endpoint(pattern: "", methods: [.get])
        let url = endpoint.url(with: ["id": "123"])
        XCTAssertEqual(url, "")
    }
    
    func testInvalidPattern() {
        let endpoint = Endpoint(pattern: "/users/id>", methods: [.get])
        let url = endpoint.url(with: ["id": "123"])
        XCTAssertEqual(url, "/users/id>")
    }
    
    // Test with single argument and placeholder
    func testURLWithSingleArg() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let url = endpoint.url(with: ["id": "1"])
        XCTAssertEqual(url, "/users/1")
    }

    // Test with multiple arguments and placeholders
    func testURLWithMultipleArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>/posts/<postId>", methods: [.get])
        let url = endpoint.url(with: ["id": "1", "postId": "99"])
        XCTAssertEqual(url, "/users/1/posts/99")
    }

    // Test with no arguments but with placeholders
    func testURLWithNoArgs() {
        let endpoint = Endpoint(pattern: "/users/<id>", methods: [.get])
        let url = endpoint.url(with: nil)
        XCTAssertNil(url)
    }

    // Test with arguments but no placeholders
    func testURLWithArgsButNoPlaceholder() {
        let endpoint = Endpoint(pattern: "/users", methods: [.get])
        let url = endpoint.url(with: ["id": "1"])
        XCTAssertEqual(url, "/users")
    }

    // Test with arguments but missing one placeholder
    func testURLWithMissingArg() {
        let endpoint = Endpoint(pattern: "/users/<id>/posts/<postId>", methods: [.get])
        let url = endpoint.url(with: ["id": "1"])
        XCTAssertEqual(url, "/users/1/posts/<postId>")
    }
}
