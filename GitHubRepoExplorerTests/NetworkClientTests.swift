//
//  NetworkClientTests.swift
//  GitHubRepoExplorerTests
//

import Testing
import Foundation
@testable import GitHubRepoExplorer

struct NetworkClientTests {
    private let session: URLSession
    private let client: NetworkClient
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        self.session = URLSession(configuration: config)
        self.client = NetworkClient(session: session)
    }
    
    // MARK: - Success Tests
    
    @Test("Successful request and decoding")
    func requestSuccess() async throws {
        let mockData = """
        { "id": 1, "name": "test-repo" }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockData)
        }
        
        let endpoint = MockEndpoint(path: "/test")
        let result: MockModel = try await client.request(endpoint: endpoint)
        
        #expect(result.id == 1)
        #expect(result.name == "test-repo")
    }
    
    // MARK: - Request Construction
    
    @Test("Correct request headers and parameters")
    func requestConstruction() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "X-Test") == "Value")
            #expect(request.url?.query?.contains("q=swift") == true)
            #expect(request.httpMethod == "GET")
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "{}".data(using: .utf8)!)
        }
        
        let endpoint = MockEndpoint(
            path: "/search",
            queryParameters: ["q": "swift"],
            headers: ["X-Test": "Value"]
        )
        
        let _: EmptyModel = try await client.request(endpoint: endpoint)
    }
    
    // MARK: - Error Handling
    
    @Test("Handle 404 Not Found")
    func handleNotFound() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let endpoint = MockEndpoint(path: "/missing")
        
        await #expect(throws: NetworkError.notFound) {
            let _: EmptyModel = try await client.request(endpoint: endpoint)
        }
    }
    
    @Test("Handle 403 Rate Limit")
    func handleRateLimit() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let endpoint = MockEndpoint(path: "/api")
        
        await #expect(throws: NetworkError.apiRateLimit) {
            let _: EmptyModel = try await client.request(endpoint: endpoint)
        }
    }
    
    @Test("Handle decoding error")
    func handleDecodingError() async throws {
        let invalidData = "invalid-json".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, invalidData)
        }
        
        let endpoint = MockEndpoint(path: "/data")
        
        do {
            let _: MockModel = try await client.request(endpoint: endpoint)
            Issue.record("Expected decoding error")
        } catch NetworkError.decodingError {
            // Success
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

// MARK: - Helper Mocks

private struct MockModel: Codable {
    let id: Int
    let name: String
}

private struct EmptyModel: Codable {}

private struct MockEndpoint: Endpoint {
    let path: String
    var queryParameters: [String : String]? = nil
    var headers: [String : String]? = nil
    
    var url: URL {
        get throws { URL(string: "https://api.test.com" + path)! }
    }
}
