//
//  MockRepositoryUpdateService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

import Combine

final class MockRepositoryUpdateService: RepositoryUpdateServiceProtocol {
    let repositoryEnrichedSubject = PassthroughSubject<Repository, Never>()
    let repositoriesEnrichedSubject = PassthroughSubject<[Repository], Never>()
    
    func publishEnrichment(_ repo: Repository) {
        
    }
    
    func publishEnrichments(_ repos: [Repository]) {
        
    }
}
