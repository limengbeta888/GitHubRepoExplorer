//
//  DependencyContainer.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import Foundation

/// A type-safe dependency manager.
final class DependencyContainer {
    static let shared = DependencyContainer()

    // Service Protocols
    private(set) var githubService: GitHubServiceProtocol
    private(set) var bookmarkService: BookmarkServiceProtocol
    private(set) var repositoryUpdateService: RepositoryUpdateServiceProtocol
    private(set) var persistenceService: PersistenceServiceProtocol
    private(set) var imageCache: ImageCacheProtocol
    private(set) var networkMonitor: NetworkMonitorProtocol

    init(
        githubService: GitHubServiceProtocol = GitHubService.shared,
        bookmarkService: BookmarkServiceProtocol = BookmarkService.shared,
        repositoryUpdateService: RepositoryUpdateServiceProtocol = RepositoryUpdateService.shared,
        persistenceService: PersistenceServiceProtocol = PersistenceService.shared,
        imageCache: ImageCacheProtocol? = nil,
        networkMonitor: NetworkMonitorProtocol = NetworkMonitor.shared
    ) {
        self.githubService = githubService
        self.bookmarkService = bookmarkService
        self.repositoryUpdateService = repositoryUpdateService
        self.persistenceService = persistenceService
        self.imageCache = imageCache ?? ImageCache.shared
        self.networkMonitor = networkMonitor
    }
    
    /// Use this method to re-initialize the container with mocks for testing.
    func register(
        githubService: GitHubServiceProtocol? = nil,
        bookmarkService: BookmarkServiceProtocol? = nil,
        repositoryUpdateService: RepositoryUpdateServiceProtocol? = nil,
        persistenceService: PersistenceServiceProtocol? = nil,
        imageCache: ImageCacheProtocol? = nil,
        networkMonitor: NetworkMonitorProtocol? = nil
    ) {
        if let githubService {
            self.githubService = githubService
        }
        
        if let bookmarkService {
            self.bookmarkService = bookmarkService
        }
        
        if let repositoryUpdateService {
            self.repositoryUpdateService = repositoryUpdateService
        }
        
        if let persistenceService {
            self.persistenceService = persistenceService
        }

        if let imageCache {
            self.imageCache = imageCache
        }

        if let networkMonitor {
            self.networkMonitor = networkMonitor
        }
    }
}
