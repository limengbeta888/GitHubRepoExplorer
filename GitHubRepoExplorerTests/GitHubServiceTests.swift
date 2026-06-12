//
//  GitHubServiceTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import Testing
import Foundation
@testable import GitHubRepoExplorer

@Suite("GitHubServiceTests Tests", .serialized)
struct GitHubServiceTests {
    @Test("Fetch detail returns cached value when not expired")
    @MainActor
    func fetchDetailReturnsCachedValue() async throws {
        let mockClient = MockNetworkClient()
        let mockPersistence = PersistenceService.inMemory()
        let service = GitHubService(client: mockClient, persistence: mockPersistence)
        
        let repo = Repository.mockOriginal
        let detail = RepositoryDetail.mockBasic
        try mockPersistence.saveDetail(detail, for: repo.fullName)
        
        let result = try await service.fetchDetail(for: repo)
        
        #expect(result.stargazersCount == detail.stargazersCount)
        #expect(mockClient.detailRequestCount == 0)
    }
    
    @Test("Fetch detail fetches from network when not cached")
    @MainActor
    func fetchDetailFromNetwork() async throws {
        let mockClient = MockNetworkClient()
        let mockPersistence = PersistenceService.inMemory()
        let service = GitHubService(client: mockClient, persistence: mockPersistence)
        
        let repo = Repository.mockOriginal
        let detail = RepositoryDetail.mockBasic
        mockClient.detailResponses[repo.fullName] = detail.toDTO()
        
        let result = try await service.fetchDetail(for: repo)
        
        #expect(result.stargazersCount == detail.stargazersCount)
        #expect(mockClient.detailRequestCount == 1)
        
        let stored = try mockPersistence.fetchDetail(for: repo.fullName, maxAge: 3600)
        #expect(stored?.stargazersCount == detail.stargazersCount)
    }
}
