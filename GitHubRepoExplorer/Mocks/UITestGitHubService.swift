//
//  UITestGitHubService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import Foundation

#if DEBUG
final class UITestGitHubService: GitHubServiceProtocol {
    func fetchRepositories() async throws -> (repos: [Repository], nextURL: URL?) {
        let next = URL(string: "https://api.github.com/repositories?since=204")!
        return ([.mockOriginal, .mockFork, .mockOrgRepo,
                 .mockZeroStars, .mockStars1to9], next)
    }
    func fetchNextRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?) {
        return ([.mockStars10to99, .mockStars100to999, .mockStars1000plus], nil)
    }
    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail {
        switch repo.id {
        case 28:   return .mockBasic
        case 1001: return .mockHighTraffic
        default:   return .mockNoLanguage
        }
    }
    func fetchDetails(for repos: [Repository]) async -> [String: RepositoryDetail] {
        var result: [String: RepositoryDetail] = [:]
        for repo in repos {
            result[repo.fullName] = (try? await fetchDetail(for: repo)) ?? .mockNoLanguage
        }
        return result
    }
}
#endif
