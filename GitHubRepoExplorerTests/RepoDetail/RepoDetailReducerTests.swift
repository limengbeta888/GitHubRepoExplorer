//
//  RepoDetailReducerTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
@testable import GitHubRepoExplorer

@MainActor
final class RepoDetailReducerTests: XCTestCase {

    private func reduce(_ state: RepoDetailState, _ intent: RepoDetailIntent) -> RepoDetailState {
        RepoDetailReducer.reduce(state, intent: intent)
    }

    // MARK: - loadDetail

    func test_loadDetail_setsLoadingDetailPhase_whenStargazersCountIsNil() {
        let state = RepoDetailState(repository: .mockOriginal)  // stargazersCount == nil
        let result = reduce(state, .loadDetail)

        XCTAssertEqual(result.phase, .loadingDetail)
    }

    func test_loadDetail_isIgnored_whenRepoAlreadyEnriched() {
        let state = RepoDetailState(repository: .mockFork)  // stargazersCount != nil
        let result = reduce(state, .loadDetail)

        // Phase starts as .loaded for enriched repos — should remain unchanged
        XCTAssertEqual(result.phase, .loaded)
    }

    // MARK: - detailLoaded

    func test_detailLoaded_mergesDetailIntoRepository() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.phase = .loadingDetail

        let result = reduce(state, .detailLoaded(.mockBasic))

        XCTAssertEqual(result.repository.stargazersCount, RepositoryDetail.mockBasic.stargazersCount)
        XCTAssertEqual(result.repository.language, RepositoryDetail.mockBasic.language)
        XCTAssertEqual(result.repository.forksCount, RepositoryDetail.mockBasic.forksCount)
        XCTAssertEqual(result.repository.openIssuesCount, RepositoryDetail.mockBasic.openIssuesCount)
    }

    func test_detailLoaded_setsLoadedPhase() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.phase = .loadingDetail

        let result = reduce(state, .detailLoaded(.mockBasic))

        XCTAssertEqual(result.phase, .loaded)
    }

    // MARK: - toggleBookmark

    func test_toggleBookmark_setsIsBookmarked_whenWasNotBookmarked() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.isBookmarked = false

        let result = reduce(state, .toggleBookmark)

        XCTAssertTrue(result.isBookmarked)
    }

    func test_toggleBookmark_clearsIsBookmarked_whenWasBookmarked() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.isBookmarked = true

        let result = reduce(state, .toggleBookmark)

        XCTAssertFalse(result.isBookmarked)
    }

    func test_toggleBookmark_doesNotAffectRepository() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.isBookmarked = false

        let result = reduce(state, .toggleBookmark)

        XCTAssertEqual(result.repository, state.repository)
    }

    // MARK: - syncBookmark

    func test_syncBookmark_setsIsBookmarkedTrue() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.isBookmarked = false

        let result = reduce(state, .syncBookmark(isBookmarked: true))

        XCTAssertTrue(result.isBookmarked)
    }

    func test_syncBookmark_setsIsBookmarkedFalse() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.isBookmarked = true

        let result = reduce(state, .syncBookmark(isBookmarked: false))

        XCTAssertFalse(result.isBookmarked)
    }

    // MARK: - fetchFailed

    func test_fetchFailed_setsErrorPhase() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.phase = .loadingDetail

        let result = reduce(state, .fetchFailed("Not found"))

        XCTAssertEqual(result.phase, .error("Not found"))
    }

    func test_fetchFailed_doesNotClearRepository() {
        var state = RepoDetailState(repository: .mockOriginal)
        state.phase = .loadingDetail

        let result = reduce(state, .fetchFailed("Something went wrong"))

        XCTAssertEqual(result.repository, state.repository)
    }
}
