//
//  BookmarkServiceTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
import Combine
@testable import GitHubRepoExplorer

@MainActor
final class BookmarkServiceTests: XCTestCase {

    private var cancellables: Set<AnyCancellable>!
    private var service: BookmarkService!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables.removeAll()
        cancellables = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createService(
        persistence: PersistenceServiceProtocol? = nil,
        repositoryUpdateService: RepositoryUpdateServiceProtocol? = nil
    ) -> BookmarkService {
        BookmarkService(
            persistence: persistence ?? MockPersistenceService(),
            repositoryUpdateService: repositoryUpdateService ?? MockRepositoryUpdateService()
        )
    }

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

    func test_addBookmark_updatesCacheAndEmits() async {
        service = createService()
        let repo = createOriginRepo()

        let expectation = expectation(description: "bookmarkAdded emitted")
        var receivedValues: [Repository] = []

        service.bookmarkAdded
            .sink {
                receivedValues.append($0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        service.addBookmark(repo)

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(service.cachedBookmarkedIDs.contains(repo.id))
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.first, repo)
    }

    func test_removeBookmark_updatesCacheAndEmits() async {
        let repo = createOriginRepo()
        let persistence = MockPersistenceService()
        persistence.storedRepos = [repo]

        service = createService(persistence: persistence)
        service.loadAllBookmarks()

        let expectation = expectation(description: "bookmarkRemoved emitted")
        var receivedValues: [Repository] = []

        service.bookmarkRemoved
            .sink {
                receivedValues.append($0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        service.removeBookmark(repo)

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertFalse(service.cachedBookmarkedIDs.contains(repo.id))
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.first, repo)
    }

    func test_updateBookmark_updatesCacheAndEmits() async {
        let repo = createOriginRepo()
        let persistence = MockPersistenceService()
        persistence.storedRepos = [repo]

        service = createService(persistence: persistence)
        service.loadAllBookmarks()

        let expectation = expectation(description: "bookmarkUpdated emitted")
        var receivedValues: [Repository] = []

        service.bookmarkUpdated
            .sink {
                receivedValues.append($0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let updatedRepo = repo.merging(detail: RepositoryDetail(
            stargazersCount: 42,
            language: "Swift",
            forksCount: 10,
            openIssuesCount: 0,
            updatedAt: nil
        ))

        service.updateBookmark(updatedRepo)

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(service.cachedBookmarks.first?.stargazersCount, 42)
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.first, updatedRepo)
    }

    func test_enrichment_fromUpdateService_updatesBookmarks() async {
        let repo = createOriginRepo()
        let persistence = MockPersistenceService()
        persistence.storedRepos = [repo]

        let updateService = MockRepositoryUpdateService()

        service = createService(
            persistence: persistence,
            repositoryUpdateService: updateService
        )

        service.loadAllBookmarks()

        let expectation = expectation(description: "bookmarkUpdated emitted")
        var receivedValues: [Repository] = []

        service.bookmarkUpdated
            .sink {
                receivedValues.append($0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let enrichedRepo = repo.merging(detail: RepositoryDetail(
            stargazersCount: 123,
            language: "Swift",
            forksCount: 5,
            openIssuesCount: 1,
            updatedAt: nil
        ))

        updateService.publishEnrichment(enrichedRepo)

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(service.cachedBookmarks.first?.stargazersCount, 123)
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.first, enrichedRepo)
    }
}
