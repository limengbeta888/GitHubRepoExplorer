//
//  ImageLoader.swift
//  GitHubRepoExplorer
//

import SwiftUI

@Observable
@MainActor
final class ImageLoader {
    var image: UIImage?
    var isLoading = false
    
    private let session: URLSession
    
    private let defaultSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
    
    init(session: URLSession? = nil) {
        self.session = session ?? defaultSession
    }
    
    func load(from url: URL?, cache: ImageCacheProtocol) async {
        guard let url else { 
            self.image = nil
            return 
        }
        
        // 1. Check cache
        if let cached = cache.image(for: url) {
            self.image = cached
            return
        }
        
        // 2. Fetch from network
        self.image = nil // Clear old image during load
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await self.session.data(from: url)
            guard let fetchedImage = UIImage(data: data) else { return }
            
            // 3. Save to cache
            cache.insertImage(fetchedImage, for: url)
            self.image = fetchedImage
        } catch {
            print("Failed to load image: \(error.localizedDescription)")
        }
    }
}
