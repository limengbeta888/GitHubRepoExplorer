//
//  MockRepositoryUpdateService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

import Combine

@MainActor
final class MockRepositoryUpdateService: RepositoryUpdateServiceProtocol {

    private let repositoryEnrichedSubject = PassthroughSubject<Repository, Never>()
    private let repositoriesEnrichedSubject = PassthroughSubject<[Repository], Never>()

    var repositoryEnriched: AnyPublisher<Repository, Never> {
        repositoryEnrichedSubject.eraseToAnyPublisher()
    }

    var repositoriesEnriched: AnyPublisher<[Repository], Never> {
        repositoriesEnrichedSubject.eraseToAnyPublisher()
    }

    func publishEnrichment(_ repo: Repository) {
        repositoryEnrichedSubject.send(repo)
    }

    func publishEnrichments(_ repos: [Repository]) {
        repositoriesEnrichedSubject.send(repos)
    }
}
