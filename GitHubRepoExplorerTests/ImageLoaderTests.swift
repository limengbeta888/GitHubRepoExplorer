//
//  ImageLoaderTests.swift
//  GitHubRepoExplorer
//

import Testing
import SwiftUI
import Foundation
@testable import GitHubRepoExplorer

@MainActor
@Suite("ImageLoader Tests")
struct ImageLoaderTests {
    
    private let url = URL(string: "https://test.com/avatar.png")!
    
    init() {
        // Setup URLProtocol for every test
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        // Note: ImageLoader uses a static session, but we can still intercept 
        // because URLProtocol is registered globally or we could refactor ImageLoader 
        // to take a session. However, the standard session.data uses the shared 
        // protocol registry if not specified.
        // Actually, ImageLoader.session is private static, let's see.
    }
    
    @Test("Load from cache hit")
    func loadFromCacheHit() async {
        let mockCache = MockImageCache()
        let testImage = UIImage()
        mockCache.stubbedImage = testImage
        
        let loader = ImageLoader()
        await loader.load(from: url, cache: mockCache)
        
        #expect(loader.image === testImage)
        #expect(loader.isLoading == false)
    }
    
    @Test("Load from network success")
    func loadFromNetworkSuccess() async throws {
        let mockCache = MockImageCache()
        let loader = ImageLoader()
        
        // Use a real image data for UIImage(data:) to work
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(rect)
        let testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let testData = testImage.pngData()!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, testData)
        }
        
        await loader.load(from: url, cache: mockCache)
        
        #expect(loader.image != nil)
        #expect(mockCache.insertedImage != nil)
        #expect(loader.isLoading == false)
    }
    
    @Test("Load from network failure")
    func loadFromNetworkFailure() async {
        let mockCache = MockImageCache()
        let loader = ImageLoader()
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        await loader.load(from: url, cache: mockCache)
        
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
