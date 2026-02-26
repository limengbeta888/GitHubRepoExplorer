//
//  RepoListStoreTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
import Combine
@testable import GitHubRepoExplorer

// Store tests verify that the correct intents are dispatched in response
// to async work and that side effects (service calls) happen correctly.
// We use MainActor since RepoListStore is @MainActor isolated.

@MainActor
final class RepoListStoreTests: XCTestCase {
    private var store: RepoListStore!
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        store = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeStore(
        gitHubService: MockGitHubService? = nil,
        bookmarkService: MockBookmarkService? = nil,
        repositoryUpdateService: MockRepositoryUpdateService? = nil
    ) -> RepoListStore {
        let container = DependencyContainer()
        container.register(
            githubService: gitHubService ?? MockGitHubService(behaviour: .success, sleepMillis: 0),
            bookmarkService: bookmarkService ?? MockBookmarkService(behaviour: .noBookmarks),
            repositoryUpdateService: repositoryUpdateService ?? MockRepositoryUpdateService()
        )
        
        return RepoListStore(
            container: container
        )
    }

    private func waitForState(
        store: RepoListStore,
        timeout: TimeInterval = 2,
        predicate: @escaping (RepoListState) -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        for try await state in store.$state.values {
            if predicate(state) { return }
            if Date() > deadline { throw XCTestError(.timeoutWhileWaiting) }
        }
    }

    private func waitForBookmarkedIDs(
        store: RepoListStore,
        contains id: Int,
        timeout: TimeInterval = 2
    ) async throws {
        try await waitForState(store: store, timeout: timeout) {
            $0.bookmarkedIDs.contains(id)
        }
    }

    private func waitForBookmarkedIDs(
        store: RepoListStore,
        notContains id: Int,
        timeout: TimeInterval = 2
    ) async throws {
        try await waitForState(store: store, timeout: timeout) {
            !$0.bookmarkedIDs.contains(id)
        }
    }

    // MARK: - loadInitial
    @MainActor
    func test_loadInitial_loadsRepositoriesOnSuccess() async throws {
        store = makeStore(gitHubService: MockGitHubService(behaviour: .success, sleepMillis: 0))
        store.dispatch(.loadInitial)

        try await waitForState(store: store) {
            !$0.repositories.isEmpty && $0.nextPageURL != nil
        }

        XCTAssertFalse(store.state.repositories.isEmpty)
        XCTAssertNotNil(store.state.nextPageURL)
    }
    
    @MainActor
    func test_loadInitial_setsErrorPhase_onNetworkError() async throws {
        store = makeStore(gitHubService: MockGitHubService(behaviour: .networkError, sleepMillis: 0))
        store.dispatch(.loadInitial)

        try await waitForState(store: store) { state in
            if case .error = state.phase { return true }
            return false
        }

        if case .error(let msg) = store.state.phase {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected error phase")
        }
    }

    // MARK: - Bookmarks

    @MainActor
    func test_bookmarkAdded_syncsBookmarkedIDsIntoState() async throws {
        let bookmarkService = MockBookmarkService(behaviour: .noBookmarks)
        store = makeStore(bookmarkService: bookmarkService)

        bookmarkService.addBookmark(.mockOriginal)

        try await waitForBookmarkedIDs(store: store, contains: Repository.mockOriginal.id)
        XCTAssertTrue(store.state.bookmarkedIDs.contains(Repository.mockOriginal.id))
    }

    @MainActor
    func test_bookmarkRemoved_syncsBookmarkedIDsIntoState() async throws {
        let bookmarkService = MockBookmarkService(behaviour: .noBookmarks)
        store = makeStore(bookmarkService: bookmarkService)

        // 1️⃣ Add bookmark
        bookmarkService.addBookmark(.mockOriginal)
        try await waitForBookmarkedIDs(store: store, contains: Repository.mockOriginal.id)
        XCTAssertTrue(store.state.bookmarkedIDs.contains(Repository.mockOriginal.id))

        // 2️⃣ Remove bookmark
        bookmarkService.removeBookmark(.mockOriginal)
        try await waitForBookmarkedIDs(store: store, notContains: Repository.mockOriginal.id)
        XCTAssertFalse(store.state.bookmarkedIDs.contains(Repository.mockOriginal.id))
    }

    // MARK: - loadMore

    @MainActor
    func test_loadMore_appendsNextPageRepos() async throws {
        store = makeStore()
        store.dispatch(.loadInitial)

        try await waitForState(store: store) { !$0.repositories.isEmpty }
        let firstCount = store.state.repositories.count

        store.dispatch(.loadMore)
        try await waitForState(store: store) { $0.repositories.count > firstCount }

        XCTAssertGreaterThan(store.state.repositories.count, firstCount)
        XCTAssertNil(store.state.nextPageURL)
    }

    // MARK: - toggleBookmark

    @MainActor
    func test_toggleBookmark_addsAndRemovesBookmarkedIDs() async throws {
        let bookmarkService = MockBookmarkService(behaviour: .noBookmarks)
        store = makeStore(bookmarkService: bookmarkService)

        store.dispatch(.toggleBookmark(.mockOriginal, isBookmarked: true))
        try await waitForBookmarkedIDs(store: store, contains: Repository.mockOriginal.id)
        XCTAssertTrue(store.state.bookmarkedIDs.contains(Repository.mockOriginal.id))

        store.dispatch(.toggleBookmark(.mockOriginal, isBookmarked: false))
        try await waitForBookmarkedIDs(store: store, notContains: Repository.mockOriginal.id)
        XCTAssertFalse(store.state.bookmarkedIDs.contains(Repository.mockOriginal.id))
    }
}
