//
//  RepositoryUpdateService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

import Combine

protocol RepositoryUpdateServiceProtocol {
    var repositoryEnriched: AnyPublisher<Repository, Never> { get }
    var repositoriesEnriched: AnyPublisher<[Repository], Never> { get }

    func publishEnrichment(_ repo: Repository)
    func publishEnrichments(_ repos: [Repository])
}

final class RepositoryUpdateService: RepositoryUpdateServiceProtocol {

    static let shared = RepositoryUpdateService()

    private let repositoryEnrichedSubject = PassthroughSubject<Repository, Never>()
    private let repositoriesEnrichedSubject = PassthroughSubject<[Repository], Never>()

    // Since we need to test this service in unit tests, init methon should not be private
    init() {}
    
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
