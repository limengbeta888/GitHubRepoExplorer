//
//  GitHubService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

// Github API Doc: https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-public-repositories

import Foundation

protocol GitHubServiceProtocol {
    func fetchRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?)
}

final class GitHubService: GitHubServiceProtocol {
    private let networkClient: NetworkClientProtocol
    private let apiConfig: GitHubAPIConfig
    
    init(networkClient: NetworkClientProtocol, apiConfig: GitHubAPIConfig) {
        self.networkClient = networkClient
        self.apiConfig = apiConfig
    }

    // MARK: Fetch Repository List

    func fetchRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?) {
        // Choose the right endpoint case based on whether this is the first page
        let endpoint = PublicReposEndpoint.repositoryList(from: url, config: apiConfig)
        let response: NetworkResponse<[Repository]> = try await networkClient.requestWithResponse(
            endpoint: endpoint
        )
        return (response.body, response.nextPageURL)
    }
    
//    // MARK: Fetch Repository Detail
//
//    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail {
//        if let cached = detailCache[repo.fullName] { return cached }
//
//        let detail: RepositoryDetail = try await client.request(
//            endpoint: RepoEndpoint.repositoryDetail(fullName: repo.fullName, config: config)
//        )
//
//        detailCache[repo.fullName] = detail
//        return detail
//    }
    
//    // MARK: Batch Detail Fetch
//
//    func fetchDetails(for repos: [Repository]) async -> [String: RepositoryDetail] {
//        await withTaskGroup(of: (String, RepositoryDetail)?.self) { group in
//            for repo in repos {
//                group.addTask {
//                    guard let detail = try? await self.fetchDetail(for: repo) else { return nil }
//                    return (repo.fullName, detail)
//                }
//            }
//            var results: [String: RepositoryDetail] = [:]
//            for await pair in group {
//                if let (key, value) = pair { results[key] = value }
//            }
//            return results
//        }
//    }
}
