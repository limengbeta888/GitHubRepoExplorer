//
//  BookmarkListStoreTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
import Combine
@testable import GitHubRepoExplorer

@MainActor
final class BookmarkListStoreTests: XCTestCase {

    // MARK: - Helpers
    
    private func makeStore(withBehaviour behaviour: MockBookmarkService.Behaviour) -> (BookmarkListStore, MockBookmarkService) {
        let service = MockBookmarkService(behaviour: behaviour)
        let store = BookmarkListStore(bookmarkService: service)
        return (store, service)
    }
    
    // Helper to wait for state changes in the store
    private func waitForState(_ store: BookmarkListStore, timeout: TimeInterval = 1.0, predicate: @escaping (BookmarkListState) -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        for try await state in store.$state.values {
            if predicate(state) { return }
            if Date() > deadline { throw XCTestError(.timeoutWhileWaiting) }
        }
    }
    
    @MainActor
    func test_loadBookmarks_whenHasBookmarks_updatesState() async {
        let mockService = MockBookmarkService(behaviour: .hasBookmarks)
        let store = BookmarkListStore(bookmarkService: mockService)

        // Dispatch loads bookmarks (sends through Combine)
        store.dispatch(.loadBookmarks)

        // Await until state is updated
        for try await state in store.$state.values {
            if state.bookmarkedRepos.count == mockService.cachedBookmarks.count {
                break
            }
        }

        XCTAssertEqual(store.state.bookmarkedRepos, mockService.cachedBookmarks)
    }

    @MainActor
    func test_loadBookmarks_whenNoBookmarks_resultsInEmptyState() async throws {
        let (store, _) = makeStore(withBehaviour: .noBookmarks)
        
        store.dispatch(.loadBookmarks)
        
        try await waitForState(store) { $0.bookmarkedRepos.isEmpty }
        
        XCTAssertTrue(store.state.bookmarkedRepos.isEmpty)
    }
    
    @MainActor
    func test_removeBookmark_updatesStateAndService() async throws {
        let (store, mockService) = makeStore(withBehaviour: .hasBookmarks)
        mockService.loadAllBookmarks()

        let repoToRemove = mockService.cachedBookmarks.first!

        let exp = XCTestExpectation(description: "Wait for bookmark removal")
        var cancellable: AnyCancellable?
        cancellable = store.$state
            .sink { state in
                if !state.bookmarkedRepos.contains(where: { $0.id == repoToRemove.id }) {
                    exp.fulfill()
                }
            }

        store.dispatch(.removeBookmark(repoToRemove))
        
        await fulfillment(of: [exp], timeout: 1)
        cancellable?.cancel()

        XCTAssertFalse(mockService.cachedBookmarkedIDs.contains(repoToRemove.id))
    }
    
    @MainActor
    func test_updateEnriched_updatesStateAndService() async throws {
        let (store, mockService) = makeStore(withBehaviour: .hasBookmarks)
        
        // Load bookmarks first
        store.dispatch(.loadBookmarks)
        try await waitForState(store) { !$0.bookmarkedRepos.isEmpty }
        
        let enriched = Repository.mockOriginal.merging(detail: .mockBasic)
        store.dispatch(.updateEnriched([enriched]))
        
        try await waitForState(store) { $0.bookmarkedRepos.first?.stargazersCount == enriched.stargazersCount }
        
        XCTAssertEqual(mockService.cachedBookmarks.first?.stargazersCount, enriched.stargazersCount)
        XCTAssertEqual(store.state.bookmarkedRepos.first?.stargazersCount, enriched.stargazersCount)
    }
}
