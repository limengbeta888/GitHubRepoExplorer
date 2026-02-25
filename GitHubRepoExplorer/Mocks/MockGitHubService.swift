//
//  MockGitHubService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

class MockGitHubService: GitHubServiceProtocol {
    enum Behaviour {
        case success
        case rateLimited
        case validationFailure
        case networkError
        case empty
    }

    let behaviour: Behaviour
    let sleepMillis: UInt32
    
    init(behaviour: Behaviour = .success, sleepMillis: UInt32 = 300) {
        self.behaviour = behaviour
        self.sleepMillis = sleepMillis
    }

    // First page — no cursor needed
    func fetchRepositories() async throws -> (repos: [Repository], nextURL: URL?) {
        try await Task.sleep(for: .milliseconds(sleepMillis))
        
        switch behaviour {
        case .rateLimited:
            throw NetworkError.apiRateLimit
        
        case .validationFailure:
            throw NetworkError.validationFailure
            
        case .networkError:
            throw NetworkError.httpError(503)
            
        case .empty:
            return ([], nil)
            
        case .success:
            let next = URL(string: "https://api.github.com/repositories?since=204")!
            return ([.mockOriginal, .mockFork, .mockOrgRepo, .mockZeroStars, .mockStars1to9], next)
        }
    }

    // Subsequent pages — cursor URL provided by Link header
    func fetchNextRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?) {
        try await Task.sleep(for: .milliseconds(sleepMillis))
        
        switch behaviour {
        case .rateLimited:
            throw NetworkError.apiRateLimit
            
        case .validationFailure:
            throw NetworkError.validationFailure
            
        case .networkError:
            throw NetworkError.httpError(503)
            
        case .empty:
            return ([], nil)
            
        case .success:
            return ([.mockStars10to99, .mockStars100to999, .mockStars1000plus], nil)
        }
    }

    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail {
        try await Task.sleep(for: .milliseconds(sleepMillis))
        
        switch behaviour {
        case .rateLimited:
            throw NetworkError.apiRateLimit
            
        case .networkError:
            throw NetworkError.httpError(503)
            
        default:
            switch repo.id {
            case 28:
                return .mockBasic
                
            case 1001:
                return .mockHighTraffic
                
            default:
                return .mockNoLanguage
            }
        }
    }

    func fetchDetails(for repos: [Repository]) async -> [String: RepositoryDetail] {
        await withTaskGroup(of: (String, RepositoryDetail)?.self) { group in
            for repo in repos {
                group.addTask {
                    guard let detail = try? await self.fetchDetail(for: repo) else { return nil }
                    return (repo.fullName, detail)
                }
            }
            var results: [String: RepositoryDetail] = [:]
            for await pair in group {
                if let (key, value) = pair { results[key] = value }
            }
            return results
        }
    }
}
