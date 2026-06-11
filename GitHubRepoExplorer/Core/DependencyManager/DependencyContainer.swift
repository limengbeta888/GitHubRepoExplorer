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

    init(
        githubService: GitHubServiceProtocol = GitHubService.shared,
        bookmarkService: BookmarkServiceProtocol = BookmarkService.shared,
        repositoryUpdateService: RepositoryUpdateServiceProtocol = RepositoryUpdateService.shared,
        persistenceService: PersistenceServiceProtocol = PersistenceService.shared
    ) {
        self.githubService = githubService
        self.bookmarkService = bookmarkService
        self.repositoryUpdateService = repositoryUpdateService
        self.persistenceService = persistenceService
    }
    
    /// Use this method to re-initialize the container with mocks for testing.
    func register(
        githubService: GitHubServiceProtocol? = nil,
        bookmarkService: BookmarkServiceProtocol? = nil,
        repositoryUpdateService: RepositoryUpdateServiceProtocol? = nil,
        persistenceService: PersistenceServiceProtocol? = nil
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
    }
}
