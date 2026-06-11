//
//  ImageCacheTests.swift
//  GitHubRepoExplorer
//

import Testing
import UIKit
import Foundation
@testable import GitHubRepoExplorer

@MainActor
@Suite("ImageCache Tests")
struct ImageCacheTests {
    
    @Test("Insert and retrieve image")
    func insertAndRetrieve() {
        let cache = ImageCache.shared
        let url = URL(string: "https://test.com/img.png")!
        let image = UIImage() // Mock image
        
        cache.insertImage(image, for: url)
        let retrieved = cache.image(for: url)
        
        #expect(retrieved === image)
        
        cache.removeImage(for: url)
    }
    
    @Test("Remove image")
    func removeImage() {
        let cache = ImageCache.shared
        let url = URL(string: "https://test.com/img2.png")!
        let image = UIImage()
        
        cache.insertImage(image, for: url)
        cache.removeImage(for: url)
        
        #expect(cache.image(for: url) == nil)
    }
    
    @Test("Clear cache")
    func clearCache() {
        let cache = ImageCache.shared
        let url1 = URL(string: "https://test.com/1.png")!
        let url2 = URL(string: "https://test.com/2.png")!
        
        cache.insertImage(UIImage(), for: url1)
        cache.insertImage(UIImage(), for: url2)
        
        cache.clear()
        
        #expect(cache.image(for: url1) == nil)
        #expect(cache.image(for: url2) == nil)
    }
    
    @Test("Nil insertion removes image")
    func nilInsertionRemoves() {
        let cache = ImageCache.shared
        let url = URL(string: "https://test.com/img3.png")!
        
        cache.insertImage(UIImage(), for: url)
        cache.insertImage(nil, for: url)
        
        #expect(cache.image(for: url) == nil)
    }
}
