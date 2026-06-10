//
//  GitHubService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

// Github API Doc: https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-public-repositories

import Foundation

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
    private let persistence: PersistenceServiceProtocol
    
    /// Cache expiry time (1 hour)
    private let detailTTL: TimeInterval = 3600

    // Since we need to test this service in unit tests, init methon should not be private
    init(
        client: NetworkClientProtocol = NetworkClient(),
        config: GitHubAPIConfig = GitHubAPIConfig(),
        persistence: PersistenceServiceProtocol = PersistenceService.shared
    ) {
        self.client = client
        self.config = config
        self.persistence = persistence
    }
    
    // MARK: - List

    func fetchRepositories() async throws -> (repos: [Repository], nextURL: URL?) {
        let response: NetworkResponse<[RepositoryDTO]> = try await client.requestWithResponse(
            endpoint: PublicReposEndpoint.repositories(config)
        )
        let domainRepos = response.body.map { $0.toDomain() }
        return (domainRepos, response.nextPageURL)
    }

    func fetchNextRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?) {
        let response: NetworkResponse<[RepositoryDTO]> = try await client.requestWithResponse(
            endpoint: PublicReposEndpoint.nextRepositories(url)
        )
        let domainRepos = response.body.map { $0.toDomain() }
        return (domainRepos, response.nextPageURL)
    }

    // MARK: - Detail (with persistent cache)

    func fetchDetail(for repo: Repository) async throws -> RepositoryDetail {
        // 1. Check persistent cache
        if let cached = try? persistence.fetchDetail(for: repo.fullName, maxAge: detailTTL) {
            return cached
        }
        
        // 2. Fetch from network
        let detailDTO: RepositoryDetailDTO = try await client.request(
            endpoint: PublicReposEndpoint.repositoryDetail(fullName: repo.fullName, config: config)
        )
        let detail = detailDTO.toDomain()
        
        // 3. Save to persistent cache
        try? persistence.saveDetail(detail, for: repo.fullName)
        
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
