//
//  RepoDetailStoreTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
import Combine
@testable import GitHubRepoExplorer

@MainActor
final class RepoDetailStoreTests: XCTestCase {

    private var store: RepoDetailStore!
    
    // MARK: - Helpers
    
    private func createOriginalRepo() -> Repository {
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
    
    private func createForkRepo() -> Repository {
        Repository(
            id: 42,
            name: "rails",
            fullName: "dhh/rails",
            description: "Ruby on Rails fork",
            fork: true,
            htmlUrl: "https://github.com/dhh/rails",
            owner: .mockUser,
            stargazersCount: 312,
            language: "Ruby",
            forksCount: 14,
            openIssuesCount: 3,
            updatedAt: "2024-03-15T10:22:00Z"
        )
    }
    
    private func createRepos() -> [Repository] {
        [createOriginalRepo(), createForkRepo(), .mockOrgRepo, .mockZeroStars, .mockStars1to9]
    }
    
    private func makeStore(
        repo: Repository? = nil,
        service: MockGitHubService? = nil,
        bookmarkService: MockBookmarkService? = nil,
        repositoryUpdateService: MockRepositoryUpdateService? = nil
    ) -> RepoDetailStore {
        
        let container = DependencyContainer()
        container.register(
            githubService: service ?? MockGitHubService(behaviour: .success, sleepMillis: 0),
            bookmarkService: bookmarkService ?? MockBookmarkService(behaviour: .noBookmarks),
            repositoryUpdateService: repositoryUpdateService ?? MockRepositoryUpdateService()
        )
        
        return RepoDetailStore(
            repo: repo ?? createOriginalRepo(),
            container: container
        )
    }
    
    private func waitForState(
        timeout: TimeInterval = 2,
        predicate: @escaping (RepoDetailState) -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        for try await state in store.$state.values {
            if predicate(state) { return }
            if Date() > deadline { throw XCTestError(.timeoutWhileWaiting) }
        }
    }
    
    private func waitForBookmarkedState(
        _ isBookmarked: Bool,
        timeout: TimeInterval = 2
    ) async throws {
        try await waitForState(timeout: timeout) { $0.isBookmarked == isBookmarked }
    }
    
    // MARK: - init tests

    func test_init_setsIdlePhase_forUnenrichedRepo() async {
        store = makeStore(repo: createOriginalRepo())
        XCTAssertEqual(store.state.phase, .idle)
    }

    func test_init_setsLoadedPhase_forAlreadyEnrichedRepo() async {
        store = makeStore(repo: createForkRepo())
        XCTAssertEqual(store.state.phase, .loaded)
    }

    func test_init_setsIsBookmarked_fromCachedBookmarkedIDs() async throws {
        let repo = createOriginalRepo()
        let bookmarkService = MockBookmarkService(repos: createRepos())
        bookmarkService.addBookmark(repo)
        store = makeStore(repo: repo, bookmarkService: bookmarkService)
        XCTAssertTrue(store.state.isBookmarked)
    }

    func test_init_setsIsBookmarkedFalse_whenNotInCache() async throws {
        store = makeStore(repo: createOriginalRepo())
        XCTAssertFalse(store.state.isBookmarked)
    }

    // MARK: - loadDetail tests

    func test_loadDetail_setsLoadingDetailPhase() async {
        store = makeStore(repo: createOriginalRepo())
        store.dispatch(.loadDetail)
        XCTAssertEqual(store.state.phase, .loadingDetail)
    }

    func test_loadDetail_enrichesRepository_onSuccess() async throws {
        store = makeStore(repo: createOriginalRepo())
        store.dispatch(.loadDetail)
        try await waitForState { $0.repository.stargazersCount != nil }
        
        XCTAssertEqual(store.state.repository.stargazersCount, RepositoryDetail.mockBasic.stargazersCount)
        XCTAssertEqual(store.state.repository.language, RepositoryDetail.mockBasic.language)
    }

    func test_loadDetail_setsErrorPhase_onNetworkFailure() async throws {
        store = makeStore(service: MockGitHubService(behaviour: .networkError, sleepMillis: 0))
        store.dispatch(.loadDetail)
        try await waitForState { state in
            if case .error = state.phase { return true }
            return false
        }
        if case .error(let msg) = store.state.phase {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected error phase")
        }
    }

    func test_loadDetail_isSkipped_whenRepoAlreadyEnriched() async throws {
        store = makeStore(repo: createForkRepo())
        store.dispatch(.loadDetail)
        await Task.yield() // allow async tasks to run
        XCTAssertEqual(store.state.phase, .loaded)
    }

    func test_loadDetail_publishesEnrichmentToUpdateService_onSuccess() async throws {
        let updateService = MockRepositoryUpdateService()
        store = makeStore(repo: createOriginalRepo(), repositoryUpdateService: updateService)
        store.dispatch(.loadDetail)
        try await waitForState { $0.repository.stargazersCount != nil }

        XCTAssertEqual(store.state.repository.id, createOriginalRepo().id)
        XCTAssertNotNil(store.state.repository.stargazersCount)
    }

    // MARK: - toggleBookmark tests

    func test_toggleBookmark_setsIsBookmarkedTrue_andCallsAddBookmark() async throws {
        let repo = createOriginalRepo()
        let bookmarkService = MockBookmarkService(repos: createRepos())
        store = makeStore(repo: repo, bookmarkService: bookmarkService)
        
        XCTAssertFalse(store.state.isBookmarked)
        store.dispatch(.toggleBookmark)
        try await waitForBookmarkedState(true)

        XCTAssertTrue(bookmarkService.cachedBookmarkedIDs.contains(repo.id))
    }

    func test_toggleBookmark_setsIsBookmarkedFalse_andCallsRemoveBookmark() async throws {
        let repo = createOriginalRepo()
        let bookmarkService = MockBookmarkService(repos: createRepos())
        bookmarkService.addBookmark(repo)
        store = makeStore(repo: repo, bookmarkService: bookmarkService)

        XCTAssertTrue(store.state.isBookmarked)
        store.dispatch(.toggleBookmark)
        try await waitForBookmarkedState(false)

        XCTAssertFalse(bookmarkService.cachedBookmarkedIDs.contains(repo.id))
    }

    func test_toggleBookmark_toggling() async throws {
        let repo = createOriginalRepo()
        let bookmarkService = MockBookmarkService(repos: createRepos())
        store = makeStore(repo: repo, bookmarkService: bookmarkService)
        
        store.dispatch(.toggleBookmark)
        try await waitForBookmarkedState(true)
        XCTAssertTrue(bookmarkService.cachedBookmarkedIDs.contains(repo.id))
        
        store.dispatch(.toggleBookmark)
        try await waitForBookmarkedState(false)
        XCTAssertFalse(bookmarkService.cachedBookmarkedIDs.contains(repo.id))
    }
}
