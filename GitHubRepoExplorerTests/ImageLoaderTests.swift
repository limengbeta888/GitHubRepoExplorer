//
//  ImageLoaderTests.swift
//  GitHubRepoExplorer
//

import Testing
import SwiftUI
import Foundation
@testable import GitHubRepoExplorer

@MainActor
@Suite("ImageLoader Tests", .serialized)
struct ImageLoaderTests {
    
    private let url = URL(string: "https://test.com/avatar_test.png")!
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        self.session = URLSession(configuration: config)
    }
    
    @Test("Load from cache hit")
    func loadFromCacheHit() async {
        let mockCache = MockImageCache()
        let testImage = UIImage()
        mockCache.stubbedImage = testImage
        
        let loader = ImageLoader(session: session)
        await loader.load(from: url, cache: mockCache)
        
        #expect(loader.image === testImage)
        #expect(loader.isLoading == false)
    }
    
    @Test("Load from network success")
    func loadFromNetworkSuccess() async throws {
        let mockCache = MockImageCache()
        let loader = ImageLoader(session: session)
        
        // Create a 1x1 pixel image to get real data
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(rect)
        let testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let testData = testImage.pngData()!
        
        MockURLProtocol.setHandler(for: "/avatar_test_success.png") { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, testData)
        }
        
        let successURL = URL(string: "https://test.com/avatar_test_success.png")!
        await loader.load(from: successURL, cache: mockCache)
        
        #expect(loader.image != nil)
        #expect(mockCache.insertedImage != nil)
        #expect(loader.isLoading == false)
    }
    
    @Test("Load from network failure")
    func loadFromNetworkFailure() async {
        let mockCache = MockImageCache()
        let loader = ImageLoader(session: session)
        
        MockURLProtocol.setHandler(for: "/avatar_test_fail.png") { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let failURL = URL(string: "https://test.com/avatar_test_fail.png")!
        await loader.load(from: failURL, cache: mockCache)
        
        #expect(loader.image == nil)
        #expect(loader.isLoading == false)
    }
}

// MARK: - Mocks

@MainActor
private final class MockImageCache: ImageCacheProtocol {
    var stubbedImage: UIImage?
    var insertedImage: UIImage?
    
    func image(for url: URL) -> UIImage? { stubbedImage }
    func insertImage(_ image: UIImage?, for url: URL) { insertedImage = image }
    func removeImage(for url: URL) {}
    func clear() {}
}
