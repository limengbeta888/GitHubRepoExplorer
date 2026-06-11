//
//  RepositoryUpdateServiceTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import Testing
import Combine
import Foundation
@testable import GitHubRepoExplorer

@Suite("RepositoryUpdateService Tests")
struct RepositoryUpdateServiceTests {
    
    @Test("Publish single repository enrichment")
    func publishSingleEnrichment() {
        let service = RepositoryUpdateService()
        let repo = Repository.mockOriginal
        var receivedRepo: Repository?
        let expectation = PassthroughSubject<Void, Never>()
        
        let cancellable = service.repositoryEnriched.sink { repo in
            receivedRepo = repo
            expectation.send()
        }
        
        service.publishEnrichment(repo)
        
        #expect(receivedRepo?.id == repo.id)
        #expect(receivedRepo?.name == repo.name)
        cancellable.cancel()
    }
    
    @Test("Publish multiple repository enrichments")
    func publishMultipleEnrichments() {
        let service = RepositoryUpdateService()
        let repos = [Repository.mockOriginal, Repository.mockFork]
        var receivedRepos: [Repository] = []
        
        let cancellable = service.repositoriesEnriched.sink { repos in
            receivedRepos = repos
        }
        
        service.publishEnrichments(repos)
        
        #expect(receivedRepos.count == 2)
        #expect(receivedRepos[0].id == repos[0].id)
        #expect(receivedRepos[1].id == repos[1].id)
        cancellable.cancel()
    }
}
