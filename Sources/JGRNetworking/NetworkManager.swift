//
//  NetworkManager.swift
//
//  Created by Jack Rostron on 03/04/2017.
//  Copyright © 2020 Jack Rostron. All rights reserved.
//

import Foundation

/// Representation of the standard HTTP request types
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Representation of an error that may occur when sending a networking request
public struct NetworkError: Error {
    public enum Reason {
        case buildingPayload
        case castingToExpectedType
        case invalidURL
        case methodNotAllowed
        case requestFailed
        case groupIncomplete
        case unknownStatus
        case unwrappingResponse
        case invalidResponseType
    }

    public let reason: Reason
    public let json: Any?

    public init(reason: Reason, json: Any? = nil) {
        self.reason = reason
        self.json = json
    }
}

/// Representation of a network success state. Allows for easy checking of request status.
/// Assiciated value contains the status code of the request
public enum APISuccessState {
    case success(Int?)
    case failure(Int?, NetworkError?)
}

/// To call the base method, we need a posting type that conforms to Codable. This empty
/// object allows us to state that we are not posting anything through to the API.
private protocol NothingProtocol {}
public struct Nothing: Codable, NothingProtocol {}

open class NetworkManager {

    // MARK: - Properties

    public var baseURL: URL
    public var headers: [String: String]?
    private static let successStatusRange = 200..<300
    private let session = URLSession(configuration: .default)

    public typealias APIResponse<R> = ((APISuccessState, R?) -> Void)?

    // MARK: - Lifecycle

    public init(baseURL url: String) {
        baseURL = URL(string: url)!
    }

    // MARK: - Public API

    public func call<R: Decodable>(_ endpoint: Endpoint,
                            with args: [String: String]? = nil,
                            using method: HTTPMethod = .get,
                            expecting response: R.Type?,
                            completion: APIResponse<R>) {
        call(endpoint, with: args, parameters: Nothing(),
             using: method, posting: Nothing(), expecting: response, completion: completion)
    }

    public func callWithParams<P: Encodable, R: Decodable>(_ endpoint: Endpoint,
                                                    with args: [String: String]? = nil,
                                                    parameters: P,
                                                    using method: HTTPMethod = .get,
                                                    expecting response: R.Type?,
                                                    completion: APIResponse<R>) {
        call(endpoint, with: args, parameters: parameters,
             using: method, posting: Nothing(), expecting: response, completion: completion)
    }

    public func post<R: Decodable, B: Encodable>(_ endpoint: Endpoint,
                                          with args: [String: String]? = nil,
                                          using method: HTTPMethod = .post,
                                          posting body: B?,
                                          expecting response: R.Type?,
                                          completion: APIResponse<R>) {
        call(endpoint, with: args, parameters: Nothing(),
             using: method, posting: body, expecting: response, completion: completion)
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func call<P: Encodable, B: Encodable, R: Decodable>(_ endpoint: Endpoint,
                                                                with args: [String: String]? = nil,
                                                                parameters params: P?,
                                                                using method: HTTPMethod = .get,
                                                                posting body: B?,
                                                                expecting responseType: R.Type?,
                                                                completion: APIResponse<R>) {

        // Prepare our URL components

        guard var urlComponents = URLComponents(string: baseURL.absoluteString) else {
            completion?(.failure(nil, NetworkError(reason: .invalidURL)), nil)
            return
        }

        guard let endpointPath = endpoint.url(with: args) else {
            completion?(.failure(nil, NetworkError(reason: .invalidURL)), nil)
            return
        }

        urlComponents.path = urlComponents.path.appending(endpointPath)

        // Apply our parameters

        applyParameters: if let parameters = try? params.asDictionary() {
            if parameters.count == 0 {
                break applyParameters
            }

            var queryItems = [URLQueryItem]()

            for (key, value) in parameters {
                if let value = value as? String {
                    let queryItem = URLQueryItem(name: key, value: value)
                    queryItems.append(queryItem)
                }
            }

            urlComponents.queryItems = queryItems
        }

        // Try to build the URL, bad request if we can't

        guard let urlString = urlComponents.url?.absoluteString.removingPercentEncoding,
            let url = URL(string: urlString) else {
                completion?(.failure(nil, NetworkError(reason: .invalidURL)), nil)
                return
        }

        // Can we call this method on this endpoint? If not, lets not try to continue

        guard endpoint.httpMethods.contains(method) else {
            completion?(.failure(nil, NetworkError(reason: .methodNotAllowed)), nil)
            return
        }
        
        // Build our request

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // If we are posting, safely retrieve the body and try to assign it to our request

        if !(body is NothingProtocol) {
            guard let body = body else {
                completion?(.failure(nil, NetworkError(reason: .buildingPayload)), nil)
                return
            }

            do {
                let result = try encode(body: body, type: endpoint.encodingType)
                request.httpBody = result.data
                request.setValue(result.headerValue, forHTTPHeaderField: "Content-Type")
            } catch {
                completion?(.failure(nil, NetworkError(reason: .buildingPayload)), nil)
                return
            }
        }
        
        // Build our response handler
        
        let task = session.dataTask(with: request as URLRequest) { (rawData, response, error) in

            // Print some logs to help track requests
            
            var debugOutput = "URL\n\(url)\n\n"
            
            if !(params is Nothing.Type) {
                debugOutput.append(contentsOf: "PARAMETERS\n\(params.asJSONString() ?? "No Parameters")\n\n")
            }
            
            if !(body is Nothing.Type) {
                debugOutput.append(contentsOf: "BODY\n\(body.asJSONString() ?? "No Body")\n\n")
            }
            
            if let responseData = rawData {
                debugOutput.append(contentsOf: "RESPONSE\n\(String(data: responseData, encoding: .utf8) ?? "No Response Content")")
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                guard error == nil else {
                    completion?(.failure(nil, NetworkError(reason: .unwrappingResponse)), nil)
                    return
                }

                completion?(.failure(nil, NetworkError(reason: .invalidResponseType)), nil)
                return
            }

            let statusCode = httpResponse.statusCode

            // We have an error, return it

            guard error == nil, NetworkManager.successStatusRange.contains(statusCode) else {
                var output: Any?

                if let data = rawData {
                    output = (try? JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments)) ?? "Unable to connect"
                }

                completion?(.failure(statusCode, NetworkError(reason: .requestFailed, json: output)), nil)
                return
            }

            // Safely cast the responseType we are expecting

            guard let responseType = responseType else {
                completion?(.failure(statusCode, NetworkError(reason: .castingToExpectedType)), nil)
                return
            }

            // If we are expecting nothing, return now (since we will have nothing!)

            if responseType is Nothing.Type {
                completion?(.success(statusCode), nil)
                return
            }

            guard let data = rawData else {
                assertionFailure("Could not cast data from payload when we passed pre-cast checks")
                return
            }

            // Decode the JSON and cast to our expected response type

            do {
                let decoder = JSONDecoder()
                if #available(iOS 11, OSX 10.12, *) {
                    decoder.dateDecodingStrategy = .iso8601
                }
                let responseObject = try decoder.decode(responseType, from: data)
                completion?(.success(statusCode), responseObject)
                return
            } catch let error {
                let content = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                print("Failed to build codable from JSON: \(String(describing: content))\n\nError: \(error)")
                completion?(.failure(statusCode, NetworkError(reason: .castingToExpectedType)), nil)
                return
            }
        }

        // Submit our request

        task.resume()
    }
    
    // MARK: - Encoding
    
    private func encode<B: Encodable>(body: B, type: EncodingType) throws -> (data: Data, headerValue: String) {
        var data: Data
        var headerValue: String
        switch type {
        case .form:
            if let parameters = try? body.asDictionary() {
                if parameters.count == 0 {
                    throw NetworkError(reason: .buildingPayload)
                }
                
                var payloadBody = String()
                
                for (key, value) in parameters {
                    if let value = value as? String {
                        
                        guard let encoded = "\(key)=\(value)&".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                            throw NetworkError(reason: .buildingPayload)
                        }
                        
                        payloadBody.append(encoded)
                    }
                }
                
                data = payloadBody.data(using: .utf8)!
                headerValue = "application/x-www-form-urlencoded"
            } else {
                throw NetworkError(reason: .buildingPayload)
            }
        case .json:
            let encoder = JSONEncoder()
            if #available(iOS 11, OSX 10.12, *) {
                encoder.dateEncodingStrategy = .iso8601
            }
            data = try encoder.encode(body)
            headerValue = "application/json"
        }
 
        return (data: data, headerValue: headerValue)
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}
