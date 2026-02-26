//
//  MockPersistenceService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

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
}
