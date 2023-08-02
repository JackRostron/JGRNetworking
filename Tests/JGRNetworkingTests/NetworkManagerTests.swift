//
//  NetworkManagerTests.swift
//  
//
//  Created by Jack Rostron on 02/08/2023.
//

import XCTest
@testable import JGRNetworking

class NetworkManagerTests: XCTestCase {
    
    var sut: NetworkManager!
    var mockSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        sut = NetworkManager(baseURL: "http://localhost:3000", session: mockSession)
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
        super.tearDown()
    }
    
    func testUserEndpointNoArgs() {
        // Given
        let userEndpoint = Endpoint(url: "/users/1", methods: [.get])
        mockSession.nextData = "{\"id\": 1, \"name\": \"John Doe\", \"email\": \"john.doe@example.com\"}".data(using: .utf8)
        mockSession.prepareMockResponse(url: URL(string: "https://myapi.com/users/1"), statusCode: 200)
        
        let expectation = self.expectation(description: "Request should finish")
        
        // When
        sut.call(userEndpoint, using: .get, expecting: User.self) { (state, user: User?) in
            
            // Then
            switch state {
            case .success(let statusCode):
                XCTAssertEqual(statusCode, 200)
                XCTAssertNotNil(user)
                XCTAssertEqual(user?.id, 1)
                XCTAssertEqual(user?.name, "John Doe")
                XCTAssertEqual(user?.email, "john.doe@example.com")
            case .failure(let statusCode, let error):
                XCTFail("Request failed with status code \(statusCode ?? 0), error: \(error?.reason ?? .unknownStatus)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testInvalidUrl() {
        // Given
        let invalidEndpoint = Endpoint(url: "invalid url", methods: [.get])
        mockSession.nextData = nil
        mockSession.prepareMockResponse(url: URL(string: "invalid url"), statusCode: 200)
        
        let expectation = self.expectation(description: "Request should fail")
        
        // When
        sut.call(invalidEndpoint, using: .get, expecting: User.self) { (state, user: User?) in
            
            // Then
            switch state {
            case .failure(_, let error):
                XCTAssertEqual(error?.reason, NetworkError.Reason.invalidURL)
                XCTAssertNil(user)
            default:
                XCTFail("Expected failure for invalid URL, got success.")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testMethodNotAllowed() {
        // Given
        let userEndpoint = Endpoint(url: "/users/1", methods: [.get]) // POST is not allowed
        mockSession.nextData = "{\"id\": 1, \"name\": \"John Doe\", \"email\": \"john.doe@example.com\"}".data(using: .utf8)
        mockSession.prepareMockResponse(url: URL(string: "https://myapi.com/users/1"), statusCode: 200)
        
        let expectation = self.expectation(description: "Request should fail")
        
        // When
        sut.post(userEndpoint, using: .post, posting: User(id: 1, name: "John Doe", email: "john.doe@example.com"), expecting: User.self) { (state, user: User?) in
            
            // Then
            switch state {
            case .failure(_, let error):
                XCTAssertEqual(error?.reason, NetworkError.Reason.methodNotAllowed)
                XCTAssertNil(user)
            default:
                XCTFail("Expected failure for method not allowed, got success.")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testNoDataReturned() {
        // Given
        let userEndpoint = Endpoint(url: "/users/1", methods: [.get])
        mockSession.nextData = nil // No data is returned
        mockSession.prepareMockResponse(url: URL(string: "https://myapi.com/users/1"), statusCode: 200)
        
        let expectation = self.expectation(description: "Request should fail")
        
        // When
        sut.call(userEndpoint, using: .get, expecting: User.self) { (state, user: User?) in
            
            // Then
            switch state {
            case .failure(_, let error):
                XCTAssertEqual(error?.reason, NetworkError.Reason.unwrappingResponse)
                XCTAssertNil(user)
            default:
                XCTFail("Expected failure for no data returned, got success.")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPostMethod() {
        // Given
        let postEndpoint = Endpoint(url: "/users", methods: [.post])
        let newUser = User(id: 2, name: "Jane Doe", email: "jane.doe@example.com")
        mockSession.nextData = "{\"id\": 2, \"name\": \"Jane Doe\", \"email\": \"jane.doe@example.com\"}".data(using: .utf8)
        mockSession.prepareMockResponse(url: URL(string: "https://myapi.com/users"), statusCode: 201)
        
        let expectation = self.expectation(description: "POST Request should succeed")
        
        // When
        sut.post(postEndpoint, using: .post, posting: newUser, expecting: User.self) { (state, user: User?) in
            
            // Then
            switch state {
            case .success(let statusCode):
                XCTAssertEqual(statusCode, 201)
                XCTAssertNotNil(user)
                XCTAssertEqual(user?.id, 2)
                XCTAssertEqual(user?.name, "Jane Doe")
                XCTAssertEqual(user?.email, "jane.doe@example.com")
            case .failure(let statusCode, let error):
                XCTFail("Request failed with status code \(statusCode ?? 0), error: \(error?.reason ?? .unknownStatus)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testInvalidJSONResponse() {
        // Given
        let userEndpoint = Endpoint(url: "/users/1", methods: [.get])
        // Invalid JSON data
        mockSession.nextData = "Invalid JSON".data(using: .utf8)
        mockSession.prepareMockResponse(url: URL(string: "https://myapi.com/users/1"), statusCode: 200)
        
        let expectation = self.expectation(description: "Request should fail")
        
        // When
        sut.call(userEndpoint, using: .get, expecting: User.self) { (state, user: User?) in
            
            // Then
            switch state {
            case .failure(_, let error):
                XCTAssertEqual(error?.reason, NetworkError.Reason.castingToExpectedType)
                XCTAssertNil(user)
            default:
                XCTFail("Expected failure for invalid JSON data, got success.")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPostMethodWithParams() {
        // Given
        let postEndpoint = Endpoint(url: "/users/<id>/details", methods: [.post])
        let details = UserDetails(id: 1, address: "123 Main St", phone: "123-456-7890")
        mockSession.nextData = "{\"id\": 1, \"address\": \"123 Main St\", \"phone\": \"123-456-7890\"}".data(using: .utf8)
        mockSession.prepareMockResponse(url: URL(string: "https://myapi.com/users/1/details"), statusCode: 201)
        
        let expectation = self.expectation(description: "POST Request with Params should succeed")
        
        // When
        sut.callWithParams(postEndpoint, with: ["id": "1"], parameters: details, using: .post, expecting: UserDetails.self) { (state, userDetails: UserDetails?) in
            
            // Then
            switch state {
            case .success(let statusCode):
                XCTAssertEqual(statusCode, 201)
                XCTAssertNotNil(userDetails)
                XCTAssertEqual(userDetails?.id, 1)
                XCTAssertEqual(userDetails?.address, "123 Main St")
                XCTAssertEqual(userDetails?.phone, "123-456-7890")
            case .failure(let statusCode, let error):
                XCTFail("Request failed with status code \(statusCode ?? 0), error: \(error?.reason ?? .unknownStatus)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    // MARK: - Tests
    
    func testGetMethodWithJSONResponse() {
        // Given
        let userEndpoint = Endpoint(url: "/users/<id>", methods: [.get])
        mockSession.nextData = "{\"id\": 1, \"name\": \"John Doe\", \"email\": \"john.doe@example.com\"}".data(using: .utf8)
        mockSession.nextResponse = HTTPURLResponse(url: URL(string: "http://localhost:3000/users/1")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let expectation = self.expectation(description: "Request should finish")
        
        // When
        sut.call(userEndpoint, with: ["id": "1"], using: .get, expecting: User.self) { (state, user: User?) in
            
            // Then
            switch state {
            case .success(let statusCode):
                XCTAssertEqual(statusCode, 200)
                XCTAssertNotNil(user)
                XCTAssertEqual(user?.id, 1)
                XCTAssertEqual(user?.name, "John Doe")
                XCTAssertEqual(user?.email, "john.doe@example.com")
            case .failure(let statusCode, let error):
                XCTFail("Request failed with status code \(statusCode ?? 0), error: \(error?.reason ?? .unknownStatus)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPostMethodWithJSONResponse() {
        // Given
        let postEndpoint = Endpoint(url: "/users", methods: [.post])
        mockSession.nextData = "{\"id\": 2, \"name\": \"Jane Doe\", \"email\": \"jane.doe@example.com\"}".data(using: .utf8)
        mockSession.nextResponse = HTTPURLResponse(url: URL(string: "http://localhost:3000/users")!, statusCode: 201, httpVersion: nil, headerFields: nil)
        let userToPost = User(id: 2, name: "Jane Doe", email: "jane.doe@example.com")
        
        let expectation = self.expectation(description: "Request should finish")
        
        // When
        sut.post(postEndpoint, with: nil, using: .post, posting: userToPost, expecting: User.self) { (state, user: User?) in
            
            // Then
            switch state {
            case .success(let statusCode):
                XCTAssertEqual(statusCode, 201)
                XCTAssertNotNil(user)
                XCTAssertEqual(user?.id, 2)
                XCTAssertEqual(user?.name, "Jane Doe")
                XCTAssertEqual(user?.email, "jane.doe@example.com")
            case .failure(let statusCode, let error):
                XCTFail("Request failed with status code \(statusCode ?? 0), error: \(error?.reason ?? .unknownStatus)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetMethodWithEmptyJSONResponse() {
        // Given
        let emptyEndpoint = Endpoint(url: "/empty", methods: [.get])
        mockSession.nextData = "{}".data(using: .utf8)
        mockSession.nextResponse = HTTPURLResponse(url: URL(string: "http://localhost:3000/empty")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let expectation = self.expectation(description: "Request should finish")
        
        // When
        sut.call(emptyEndpoint, with: nil, using: .get, expecting: Nothing.self) { (state, empty: Nothing?) in
            
            // Then
            switch state {
            case .success(let statusCode):
                XCTAssertEqual(statusCode, 200)
                XCTAssertNil(empty)
            case .failure(let statusCode, let error):
                XCTFail("Request failed with status code \(statusCode ?? 0), error: \(error?.reason ?? .unknownStatus)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetMethodWithNonexistentEndpoint() {
        // Given
        let nonexistentEndpoint = Endpoint(url: "/nonexistent", methods: [.get])
        mockSession.nextError = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: nil)
        
        let expectation = self.expectation(description: "Request should finish")
        
        // When
        sut.call(nonexistentEndpoint, with: nil, using: .get, expecting: Nothing.self) { (state, _: Nothing?) in
            
            // Then
            switch state {
            case .success(_):
                XCTFail("Request should not succeed")
            case .failure(let statusCode, let error):
                XCTAssertNil(statusCode)
                XCTAssertEqual(error?.reason, NetworkError.Reason.unwrappingResponse)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

// MARK: - Supporting Test Models

class MockURLSession: URLSessionProtocol {
    private (set) var lastURL: URL?
    var nextDataTask = MockURLSessionDataTask()
    var nextData: Data?
    var nextError: Error?
    var nextResponse: HTTPURLResponse?
    
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        lastURL = request.url
        
        completionHandler(nextData, nextResponse, nextError)
        
        return nextDataTask
    }
    
    func prepareMockResponse(url: URL?, statusCode: Int, httpVersion: String? = nil, headerFields: [String: String]? = nil) {
        nextResponse = HTTPURLResponse(url: url ?? URL(fileURLWithPath: ""), statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)
    }
}

class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    private (set) var resumeWasCalled = false
    
    func resume() {
        resumeWasCalled = true
    }
}

// User model
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// Post model
struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct UserDetails: Codable {
    let id: Int
    let address: String
    let phone: String
}
