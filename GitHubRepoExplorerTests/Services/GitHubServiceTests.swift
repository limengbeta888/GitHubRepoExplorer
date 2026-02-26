//
//  GitHubServiceTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
@testable import GitHubRepoExplorer

@MainActor
final class GitHubServiceTests: XCTestCase {

    private var client: MockNetworkClient!
    private var service: GitHubService!

    override func setUp() {
        super.setUp()
        client = MockNetworkClient()
        service = GitHubService(client: client)
    }

    override func tearDown() {
        service = nil
        client = nil
        super.tearDown()
    }

    // MARK: - fetchRepositories

    func test_fetchRepositories_returnsExpectedList() async throws {
        let repo = Repository.mockOriginal
        client.repositoryListResponse = [repo]

        let result = try await service.fetchRepositories()

        XCTAssertEqual(result.repos, [repo])
        XCTAssertNil(result.nextURL)
        XCTAssertEqual(client.listRequestCount, 1)
    }

    // MARK: - fetchDetail (Cache)

    func test_fetchDetail_usesCache_onSecondCall() async throws {
        let repo = Repository.mockOriginal
        let detail = RepositoryDetail(
            stargazersCount: 42,
            language: "Swift",
            forksCount: 1,
            openIssuesCount: 0,
            updatedAt: nil
        )

        client.detailResponses[repo.fullName] = detail

        let first = try await service.fetchDetail(for: repo)
        let second = try await service.fetchDetail(for: repo)

        XCTAssertEqual(first.stargazersCount, 42)
        XCTAssertEqual(second.stargazersCount, 42)

        XCTAssertEqual(client.detailRequestCount, 1, "Second call should use cache")
    }

    // MARK: - fetchDetails (Batch)

    func test_fetchDetails_batch_returnsOnlySuccessful() async {
        let repo1 = Repository.mockOriginal
        let repo2 = Repository.mockFork

        let detail1 = RepositoryDetail(
            stargazersCount: 10,
            language: "Swift",
            forksCount: 1,
            openIssuesCount: 0,
            updatedAt: nil
        )

        client.detailResponses[repo1.fullName] = detail1
        // repo2 intentionally missing to simulate failure

        let results = await service.fetchDetails(for: [repo1, repo2])

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[repo1.fullName]?.stargazersCount, 10)
        XCTAssertNil(results[repo2.fullName])
    }

    // MARK: - Concurrency safety

    func test_fetchDetails_isConcurrent_andCachesIndividually() async {
        let repo1 = Repository.mockOriginal
        let repo2 = Repository.mockFork

        let detail1 = RepositoryDetail(
            stargazersCount: 10,
            language: "Swift",
            forksCount: 1,
            openIssuesCount: 0,
            updatedAt: nil
        )

        let detail2 = RepositoryDetail(
            stargazersCount: 20,
            language: "Kotlin",
            forksCount: 2,
            openIssuesCount: 1,
            updatedAt: nil
        )

        client.detailResponses[repo1.fullName] = detail1
        client.detailResponses[repo2.fullName] = detail2

        let results = await service.fetchDetails(for: [repo1, repo2])

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[repo1.fullName]?.stargazersCount, 10)
        XCTAssertEqual(results[repo2.fullName]?.stargazersCount, 20)

        XCTAssertEqual(client.detailRequestCount, 2)
    }
}
