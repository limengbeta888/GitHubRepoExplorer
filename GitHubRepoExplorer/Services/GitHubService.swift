//
//  GitHubService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

// Github API Doc: https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-public-repositories

import Foundation

// MARK: - Protocol

protocol GitHubServiceProtocol {
    func fetchRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?)
    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail
    func fetchDetails(for repos: [Repository]) async -> [String: RepositoryDetail]
}

// MARK: - Implementation

actor GitHubService: GitHubServiceProtocol {

    static let shared = GitHubService()

    private let client: NetworkClientProtocol
    private let config: GitHubAPIConfig
    private var detailCache: [String: RepositoryDetail] = [:]

    init(
        client: NetworkClientProtocol = NetworkClient(),
        config: GitHubAPIConfig = GitHubAPIConfig()
    ) {
        self.client = client
        self.config = config
    }

    // MARK: List

    func fetchRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?) {
        let endpoint = PublicReposEndpoint.repositoryList(from: url, config: config)
        let response: NetworkResponse<[Repository]> = try await client.requestWithResponse(endpoint: endpoint)
        return (response.body, response.nextPageURL)
    }

    // MARK: Detail (with actor-isolated cache)

    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail {
        if let cached = detailCache[repo.fullName] { return cached }
        let detail: RepositoryDetail = try await client.request(
            endpoint: PublicReposEndpoint.repositoryDetail(fullName: repo.fullName, config: config)
        )
        detailCache[repo.fullName] = detail
        return detail
    }

    // MARK: Batch detail — concurrent, individual failures skipped gracefully

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
