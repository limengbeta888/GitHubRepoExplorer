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
struct BookmarkServiceTests {
    
    @Test("Add bookmark updates cache and notifies observers")
    func addBookmark() async throws {
        let mockPersistence = MockPersistenceService()
        let service = BookmarkService(persistence: mockPersistence, repositoryUpdateService: MockRepositoryUpdateService())
        let repo = Repository.mockOriginal
        
        service.addBookmark(repo)
        
        #expect(service.cachedBookmarkedIDs.contains(repo.id))
        #expect(mockPersistence.addCalled)
    }
    
    @Test("Remove bookmark updates cache and notifies observers")
    func removeBookmark() async throws {
        let mockPersistence = MockPersistenceService()
        let service = BookmarkService(persistence: mockPersistence, repositoryUpdateService: MockRepositoryUpdateService())
        let repo = Repository.mockOriginal
        
        service.addBookmark(repo)
        service.removeBookmark(repo)
        
        #expect(!service.cachedBookmarkedIDs.contains(repo.id))
        #expect(mockPersistence.removeCalled)
    }
}
