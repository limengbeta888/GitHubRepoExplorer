//
//  ImageCache.swift
//  GitHubRepoExplorer
//

import UIKit

protocol ImageCacheProtocol {
    func image(for url: URL) -> UIImage?
    func insertImage(_ image: UIImage?, for url: URL)
    func removeImage(for url: URL)
    func clear()
}

@MainActor
final class ImageCache: ImageCacheProtocol {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        // Cache up to 100 images or 50MB
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func insertImage(_ image: UIImage?, for url: URL) {
        guard let image else {
            removeImage(for: url)
            return
        }
        cache.setObject(image, forKey: url as NSURL)
    }
    
    func removeImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
