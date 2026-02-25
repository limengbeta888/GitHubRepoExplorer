//
//  RepositoryUpdateService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

import Combine

protocol RepositoryUpdateServiceProtocol {
    var repositoryEnrichedSubject: PassthroughSubject<Repository, Never> { get }
    var repositoriesEnrichedSubject: PassthroughSubject<[Repository], Never> { get }
    
    func publishEnrichment(_ repo: Repository)
    func publishEnrichments(_ repos: [Repository])
}

final class RepositoryUpdateService: RepositoryUpdateServiceProtocol {
    static let shared = RepositoryUpdateService()
    let repositoryEnrichedSubject = PassthroughSubject<Repository, Never>()
    let repositoriesEnrichedSubject = PassthroughSubject<[Repository], Never>()
    
    private init() {}

    func publishEnrichment(_ repo: Repository) {
        repositoryEnrichedSubject.send(repo)
    }
    
    func publishEnrichments(_ repos: [Repository]) {
        repositoriesEnrichedSubject.send(repos)
    }
}
