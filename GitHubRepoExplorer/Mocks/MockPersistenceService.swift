//
//  MockPersistenceService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

final class MockPersistenceService: PersistenceServiceProtocol {

    private(set) var storage: [Repository] = []

    func add(_ repo: Repository) throws {
        guard !storage.contains(where: { $0.id == repo.id }) else { return }
        storage.insert(repo, at: 0)
    }

    func remove(_ repo: Repository) throws {
        storage.removeAll { $0.id == repo.id }
    }

    func update(_ repo: Repository) throws {
        guard let index = storage.firstIndex(where: { $0.id == repo.id }) else { return }
        storage[index] = repo
    }

    func loadAllRepos() throws -> [Repository] { storage }

    func deleteAllRepos() throws { storage.removeAll() }
}
