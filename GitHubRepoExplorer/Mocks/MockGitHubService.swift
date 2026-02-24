//
//  MockGitHubService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

actor MockGitHubService: GitHubServiceProtocol {

    enum Behaviour { case success, rateLimited, networkError, empty }

    let behaviour: Behaviour
    init(behaviour: Behaviour = .success) { self.behaviour = behaviour }

    func fetchRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?) {
        try await Task.sleep(for: .milliseconds(300))
        switch behaviour {
        case .rateLimited:  throw NetworkError.apiRateLimit
        case .networkError: throw NetworkError.httpError(503)
        case .empty:        return ([], nil)
        case .success:
            let isNextPage = url.query?.contains("since") == true
            if isNextPage {
                return ([.mockStars10to99, .mockStars100to999, .mockStars1000plus], nil)
            } else {
                let next = URL(string: "https://api.github.com/repositories?since=204")!
                return ([.mockOriginal, .mockFork, .mockOrgRepo, .mockZeroStars, .mockStars1to9], next)
            }
        }
    }

    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail {
        try await Task.sleep(for: .milliseconds(150))
        switch behaviour {
        case .rateLimited:  throw NetworkError.apiRateLimit
        case .networkError: throw NetworkError.httpError(503)
        default:
            switch repo.id {
            case 28:   return .mockBasic
            case 1001: return .mockHighTraffic
            default:   return .mockNoLanguage
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
