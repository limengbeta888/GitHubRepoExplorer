//
//  BookmarkListReducerTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
@testable import GitHubRepoExplorer

@MainActor
final class BookmarkListReducerTests: XCTestCase {

    @MainActor
    func test_bookmarksLoaded_replacesState() {
        let initial = BookmarkListState()
        let newState = BookmarkListReducer.reduce(
            initial,
            intent: .bookmarksLoaded([.mockFork, .mockOriginal])
        )

        XCTAssertEqual(newState.bookmarkedRepos, [.mockFork, .mockOriginal])
    }

    @MainActor
    func test_removeBookmark_removesCorrectRepo() {
        let initial = BookmarkListState(bookmarkedRepos: [.mockFork, .mockOriginal])

        let newState = BookmarkListReducer.reduce(
            initial,
            intent: .removeBookmark(.mockFork)
        )

        XCTAssertEqual(newState.bookmarkedRepos, [.mockOriginal])
    }

    @MainActor
    func test_updateEnriched_updatesMatchingRepoOnly() {
        let enrichedOriginal = Repository(
            id: 28,
            name: "god",
            fullName: "mojombo/god",
            description: "Ruby process monitor",
            fork: false,
            htmlUrl: "https://github.com/mojombo/god",
            owner: .mockUser,
            stargazersCount: 100,
            language: "C",
            forksCount: nil,
            openIssuesCount: nil,
            updatedAt: nil
        )
        
        let initial = BookmarkListState(bookmarkedRepos: [.mockFork, .mockOriginal])

        let newState = BookmarkListReducer.reduce(
            initial,
            intent: .updateEnriched([enrichedOriginal])
        )

        XCTAssertEqual(newState.bookmarkedRepos[1].stargazersCount, 100)
        XCTAssertEqual(newState.bookmarkedRepos[1].language, "C")
    }
}
