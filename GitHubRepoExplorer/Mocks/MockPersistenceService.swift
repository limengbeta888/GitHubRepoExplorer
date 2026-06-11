//
//  MockPersistenceService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import Foundation

@MainActor
final class MockPersistenceService: PersistenceServiceProtocol {
    var storedRepos: [Repository] = []
    var addCalled = false
    var removeCalled = false
    var updateCalled = false
    var deleteAllCalled = false

    func add(_ repo: Repository) throws {
        addCalled = true
        storedRepos.append(repo)
    }

    func remove(_ repo: Repository) throws {
        removeCalled = true
        storedRepos.removeAll { $0.id == repo.id }
    }

    func update(_ repo: Repository) throws {
        updateCalled = true
        if let index = storedRepos.firstIndex(where: { $0.id == repo.id }) {
            storedRepos[index] = repo
        }
    }

    func loadAllRepos() throws -> [Repository] {
        storedRepos
    }

    func deleteAllRepos() throws {
        deleteAllCalled = true
        storedRepos.removeAll()
    }
    
    // MARK: - Detail Cache
    
    var cachedDetails: [String: RepositoryDetail] = [:]
    var lastFetchedAt: [String: Date] = [:]
    
    func saveDetail(_ detail: RepositoryDetail, for fullName: String) throws {
        cachedDetails[fullName] = detail
        lastFetchedAt[fullName] = Date()
    }
    
    func fetchDetail(for fullName: String, maxAge: TimeInterval) throws -> RepositoryDetail? {
        guard let detail = cachedDetails[fullName],
              let date = lastFetchedAt[fullName] else { return nil }
        
        let age = Date().timeIntervalSince(date)
        if age > maxAge { return nil }
        
        return detail
    }
}
