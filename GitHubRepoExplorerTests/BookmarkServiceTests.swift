//
//  GitHubRepoExplorerTests.swift
//  GitHubRepoExplorerTests
//
//  Created by Meng Li on 10/06/2026.
//

import Testing
import Foundation
import Combine
@testable import GitHubRepoExplorer

@MainActor
@Suite("BookmarkServiceTests Tests", .serialized)
struct BookmarkServiceTests {
    
    @Test("Add bookmark updates cache and notifies observers")
    func addBookmark() async throws {
        let mockPersistence = PersistenceService.inMemory()
        let service = BookmarkService(persistence: mockPersistence, repositoryUpdateService: MockRepositoryUpdateService())
        let repo = Repository.mockOriginal
        
        service.addBookmark(repo)
        
        #expect(service.cachedBookmarkedIDs.contains(repo.id))
        let stored = try mockPersistence.loadAllRepos()
        #expect(stored.count == 1)
    }
    
    @Test("Remove bookmark updates cache and notifies observers")
    func removeBookmark() async throws {
        let mockPersistence = PersistenceService.inMemory()
        let service = BookmarkService(persistence: mockPersistence, repositoryUpdateService: MockRepositoryUpdateService())
        let repo = Repository.mockOriginal
        
        service.addBookmark(repo)
        service.removeBookmark(repo)
        
        #expect(!service.cachedBookmarkedIDs.contains(repo.id))
        let stored = try mockPersistence.loadAllRepos()
        #expect(stored.isEmpty)
    }
}
