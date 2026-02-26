//
//  GitHubService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

// Github API Doc: https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-public-repositories

import Foundation

// MARK: - DetailCache

private actor DetailCache {
    private var storage: [String: RepositoryDetail] = [:]

    func value(for key: String) -> RepositoryDetail? {
        storage[key]
    }

    func insert(_ value: RepositoryDetail, for key: String) {
        storage[key] = value
    }
}

// MARK: - Protocol

protocol GitHubServiceProtocol {
    func fetchRepositories() async throws -> (repos: [Repository], nextURL: URL?)
    func fetchNextRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?)
    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail
    func fetchDetails(for repos: [Repository]) async -> [String: RepositoryDetail]
}

// MARK: - Implementation

class GitHubService: GitHubServiceProtocol {
    static let shared = GitHubService()

    private let client: NetworkClientProtocol
    private let config: GitHubAPIConfig
    private let cache = DetailCache()

    init(
        client: NetworkClientProtocol = NetworkClient(),
        config: GitHubAPIConfig = GitHubAPIConfig()
    ) {
        self.client = client
        self.config = config
    }
    
    // MARK: - List

    func fetchRepositories() async throws -> (repos: [Repository], nextURL: URL?) {
        let response: NetworkResponse<[Repository]> = try await client.requestWithResponse(
            endpoint: PublicReposEndpoint.repositories(config)
        )
        return (response.body, response.nextPageURL)
    }

    func fetchNextRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?) {
        let response: NetworkResponse<[Repository]> = try await client.requestWithResponse(
            endpoint: PublicReposEndpoint.nextRepositories(url)
        )
        return (response.body, response.nextPageURL)
    }

    // MARK: - Detail (with actor-isolated cache)

    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail {
        if let cached = await cache.value(for: repo.fullName) { return cached }
        let detail: RepositoryDetail = try await client.request(
            endpoint: PublicReposEndpoint.repositoryDetail(fullName: repo.fullName, config: config)
        )
        await cache.insert(detail, for: repo.fullName)
        return detail
    }

    // MARK: Batch detail — concurrent, individual failures skipped gracefully

    func fetchDetails(for repos: [Repository]) async -> [String: RepositoryDetail] {
        await withTaskGroup(of: (String, RepositoryDetail)?.self) { group in
            for repo in repos {
                group.addTask {
                    guard let detail = try? await self.fetchDetail(for: repo) else {
                        return nil
                    }
                    return (repo.fullName, detail)
                }
            }
            
            var results: [String: RepositoryDetail] = [:]
            for await pair in group {
                if let (key, value) = pair {
                    results[key] = value
                }
            }
            return results
        }
    }
}
