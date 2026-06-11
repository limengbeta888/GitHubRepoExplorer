//
//  GitHubServiceTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import Testing
import Foundation
@testable import GitHubRepoExplorer

struct GitHubServiceTests {
    @Test("Fetch detail returns cached value when not expired")
    @MainActor
    func fetchDetailReturnsCachedValue() async throws {
        let mockClient = MockNetworkClient()
        let mockPersistence = MockPersistenceService()
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
        let mockPersistence = MockPersistenceService()
        let service = GitHubService(client: mockClient, persistence: mockPersistence)
        
        let repo = Repository.mockOriginal
        let detail = RepositoryDetail.mockBasic
        mockClient.detailResponses[repo.fullName] = detail.toDTO()
        
        let result = try await service.fetchDetail(for: repo)
        
        #expect(result.stargazersCount == detail.stargazersCount)
        #expect(mockClient.detailRequestCount == 1)
        #expect(mockPersistence.cachedDetails[repo.fullName]?.stargazersCount == detail.stargazersCount)
    }
    
    @Test("Fetch detail fetches from network when cache is expired")
    @MainActor
    func fetchDetailFromNetworkWhenExpired() async throws {
        let mockClient = MockNetworkClient()
        let mockPersistence = MockPersistenceService()
        let service = GitHubService(client: mockClient, persistence: mockPersistence)
        
        let repo = Repository.mockOriginal
        let oldDetail = RepositoryDetail.mockNoLanguage
        let newDetail = RepositoryDetail.mockBasic
        
        try mockPersistence.saveDetail(oldDetail, for: repo.fullName)
        // Manually set an old date in the mock
        mockPersistence.lastFetchedAt[repo.fullName] = Date().addingTimeInterval(-4000) // TTL is 3600
        
        mockClient.detailResponses[repo.fullName] = newDetail.toDTO()
        
        let result = try await service.fetchDetail(for: repo)
        
        #expect(result.stargazersCount == newDetail.stargazersCount)
        #expect(mockClient.detailRequestCount == 1)
    }
}
