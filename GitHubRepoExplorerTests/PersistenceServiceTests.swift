//
//  PersistenceServiceTests.swift
//  GitHubRepoExplorer
//

import Testing
import Foundation
import SwiftData
@testable import GitHubRepoExplorer

@MainActor
@Suite("PersistenceService Tests")
struct PersistenceServiceTests {
    
    @Test("Add and load repositories")
    func addAndLoad() throws {
        let sut = PersistenceService.inMemory()
        let repo = Repository.mockOriginal
        
        try sut.add(repo)
        let loaded = try sut.loadAllRepos()
        
        #expect(loaded.count == 1)
        #expect(loaded[0].id == repo.id)
        #expect(loaded[0].name == repo.name)
    }
    
    @Test("Remove repository")
    func remove() throws {
        let sut = PersistenceService.inMemory()
        let repo = Repository.mockOriginal
        
        try sut.add(repo)
        try sut.remove(repo)
        
        let loaded = try sut.loadAllRepos()
        #expect(loaded.isEmpty)
    }
    
    @Test("Delete all repositories")
    func deleteAll() throws {
        let sut = PersistenceService.inMemory()
        try sut.add(Repository.mockOriginal)
        try sut.add(Repository.mockFork)
        
        try sut.deleteAllRepos()
        
        let loaded = try sut.loadAllRepos()
        #expect(loaded.isEmpty)
    }
    
    @Test("Save and fetch details with expiry")
    func detailsCache() throws {
        let sut = PersistenceService.inMemory()
        let fullName = "test/repo"
        let detail = RepositoryDetail.mockBasic
        
        // 1. Save
        try sut.saveDetail(detail, for: fullName)
        
        // 2. Fetch (valid)
        let fetched = try sut.fetchDetail(for: fullName, maxAge: 100)
        #expect(fetched?.stargazersCount == detail.stargazersCount)
        
        // 3. Fetch (expired)
        // Since we can't easily travel in time with real SwiftData models here without complex mocks,
        // we'll just verify the -1 maxAge correctly returns nil.
        let expired = try sut.fetchDetail(for: fullName, maxAge: -1)
        #expect(expired == nil)
    }
}
