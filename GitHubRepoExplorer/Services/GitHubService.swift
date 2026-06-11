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
    private let persistence: PersistenceServiceProtocol
    
    /// Cache expiry time (1 hour)
    private let detailTTL: TimeInterval = 3600

    // Since we need to test this service in unit tests, init methon should not be private
    init(
        client: NetworkClientProtocol = NetworkClient(),
        persistence: PersistenceServiceProtocol = PersistenceService.shared
    ) {
        self.client = client
        self.persistence = persistence
    }
    
    // MARK: - List

    func fetchRepositories() async throws -> (repos: [Repository], nextURL: URL?) {
        let response: NetworkResponse<[RepositoryDTO]> = try await client.requestWithResponse(
            endpoint: PublicReposEndpoint.repositories
        )
        let domainRepos = response.body.map { mapToDomain($0) }
        return (domainRepos, response.nextPageURL)
    }

    func fetchNextRepositories(url: URL) async throws -> (repos: [Repository], nextURL: URL?) {
        let response: NetworkResponse<[RepositoryDTO]> = try await client.requestWithResponse(
            endpoint: PublicReposEndpoint.nextRepositories(url)
        )
        let domainRepos = response.body.map { mapToDomain($0) }
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
            endpoint: PublicReposEndpoint.repositoryDetail(fullName: repo.fullName)
        )
        let detail = mapToDomain(detailDTO)
        
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

    // MARK: - Private Mappers

    private func mapToDomain(_ dto: RepositoryDTO) -> Repository {
        Repository(
            id: dto.id,
            name: dto.name,
            fullName: dto.fullName,
            description: dto.description,
            fork: dto.fork,
            htmlUrl: dto.htmlUrl,
            owner: mapToDomain(dto.owner),
            stargazersCount: dto.stargazersCount,
            language: dto.language,
            forksCount: dto.forksCount,
            openIssuesCount: dto.openIssuesCount,
            updatedAt: dto.updatedAt
        )
    }

    private func mapToDomain(_ dto: OwnerDTO) -> Owner {
        Owner(login: dto.login, avatarUrl: dto.avatarUrl, type: dto.type)
    }

    private func mapToDomain(_ dto: RepositoryDetailDTO) -> RepositoryDetail {
        RepositoryDetail(
            stargazersCount: dto.stargazersCount,
            language: dto.language,
            forksCount: dto.forksCount,
            openIssuesCount: dto.openIssuesCount,
            updatedAt: dto.updatedAt
        )
    }
}
