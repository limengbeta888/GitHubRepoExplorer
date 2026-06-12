//
//  MockURLProtocol.swift
//  GitHubRepoExplorerTests
//

import Foundation

final class MockURLProtocol: URLProtocol {
    /// Handlers keyed by URL path to support parallel testing
    private static var handlers: [String: (URLRequest) throws -> (HTTPURLResponse, Data?)] = [:]
    private static let lock = NSRecursiveLock()
    
    static func setHandler(for path: String, handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data?)) {
        lock.lock()
        handlers[path] = handler
        lock.unlock()
    }
    
    static func reset() {
        lock.lock()
        handlers.removeAll()
        lock.unlock()
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let path = request.url?.path ?? ""
        
        MockURLProtocol.lock.lock()
        let handler = MockURLProtocol.handlers[path]
        MockURLProtocol.lock.unlock()
        
        guard let handler = handler else {
            // Fallback to a default error if no handler matches the path
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        do {
            let (response, data) = try handler(request)
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}
