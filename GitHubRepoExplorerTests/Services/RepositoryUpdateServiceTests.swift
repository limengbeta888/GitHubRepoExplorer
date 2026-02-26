//
//  RepositoryUpdateServiceTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
import Combine
@testable import GitHubRepoExplorer
import XCTest
import Combine
@testable import GitHubRepoExplorer

@MainActor
final class RepositoryUpdateServiceTests: XCTestCase {

    private var cancellables: Set<AnyCancellable>!
    private var service: RepositoryUpdateService!

    override func setUp() {
        super.setUp()
        cancellables = []
        service = RepositoryUpdateService()
    }

    override func tearDown() {
        cancellables.removeAll()
        cancellables = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createOriginRepo() -> Repository {
        Repository(
            id: 28,
            name: "god",
            fullName: "mojombo/god",
            description: "Ruby process monitor",
            fork: false,
            htmlUrl: "https://github.com/mojombo/god",
            owner: .mockUser,
            stargazersCount: nil,
            language: nil,
            forksCount: nil,
            openIssuesCount: nil,
            updatedAt: nil
        )
    }

    // MARK: - Tests

    func test_publishEnrichment_emitsSingleRepo() async {
        let repo = createOriginRepo()
        let expectation = expectation(description: "repositoryEnriched emitted")

        var receivedValues: [Repository] = []

        service.repositoryEnriched
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        service.publishEnrichment(repo)

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.first, repo)
    }

    func test_publishEnrichments_emitsArray() async {
        let repos = [createOriginRepo()]
        let expectation = expectation(description: "repositoriesEnriched emitted")

        var receivedValues: [[Repository]] = []

        service.repositoriesEnriched
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        service.publishEnrichments(repos)

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.first, repos)
    }
}
