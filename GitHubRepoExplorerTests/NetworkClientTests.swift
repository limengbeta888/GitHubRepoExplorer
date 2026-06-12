//
//  NetworkClientTests.swift
//  GitHubRepoExplorerTests
//

import Testing
import Foundation
@testable import GitHubRepoExplorer

@Suite("NetworkClient Tests", .serialized)
struct NetworkClientTests {
    
    // MARK: - Success Tests
    
    @Test("Successful request and decoding")
    func requestSuccess() async throws {
        let client = createClient()
        
        let mockData = """
        { "id": 1, "name": "test-repo" }
        """.data(using: .utf8)!
        
        MockURLProtocol.setHandler(for: "/test_success") { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockData)
        }
        
        let endpoint = MockEndpoint(path: "/test_success")
        let result: MockModel = try await client.request(endpoint: endpoint)
        
        #expect(result.id == 1)
        #expect(result.name == "test-repo")
    }
    
    // MARK: - Request Construction
    
    @Test("Correct request headers and parameters")
    func requestConstruction() async throws {
        let client = createClient()
        
        MockURLProtocol.setHandler(for: "/search") { request in
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
        let client = createClient()
        
        MockURLProtocol.setHandler(for: "/missing") { request in
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
        let client = createClient()
        
        MockURLProtocol.setHandler(for: "/api_limit") { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let endpoint = MockEndpoint(path: "/api_limit")
        
        await #expect(throws: NetworkError.apiRateLimit) {
            let _: EmptyModel = try await client.request(endpoint: endpoint)
        }
    }
    
    @Test("Handle decoding error")
    func handleDecodingError() async throws {
        let client = createClient()
        let invalidData = "invalid-json".data(using: .utf8)!
        
        MockURLProtocol.setHandler(for: "/invalid_data") { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, invalidData)
        }
        
        let endpoint = MockEndpoint(path: "/invalid_data")
        
        do {
            let _: MockModel = try await client.request(endpoint: endpoint)
            Issue.record("Expected decoding error")
        } catch NetworkError.decodingError {
            // Success
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Helper
    private func createClient() -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return NetworkClient(session: session)
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
