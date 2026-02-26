//
//  RepoListReducerTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
@testable import GitHubRepoExplorer

@MainActor
final class RepoListReducerTests: XCTestCase {

    // Convenience
    private func reduce(_ state: RepoListState, _ intent: RepoListIntent) -> RepoListState {
        RepoListReducer.reduce(state, intent: intent)
    }

    // MARK: - loadInitial

    func test_loadInitial_resetsRepositoriesAndSetsLoadingPhase() {
        var state = RepoListState()
        state.repositories = [.mockOriginal, .mockFork]
        state.nextPageURL = URL(string: "https://api.github.com/repositories?since=100")

        let result = reduce(state, .loadInitial)

        XCTAssertEqual(result.phase, .loadingInitial)
        XCTAssertTrue(result.repositories.isEmpty)
        XCTAssertNil(result.nextPageURL)
    }

    // MARK: - loadMore

    func test_loadMore_setsLoadingMorePhase_whenHasMorePagesAndNotFetching() {
        var state = RepoListState()
        state.phase = .loaded
        state.nextPageURL = URL(string: "https://api.github.com/repositories?since=100")

        let result = reduce(state, .loadMore)

        XCTAssertEqual(result.phase, .loadingMore)
    }

    func test_loadMore_isIgnored_whenNoMorePages() {
        var state = RepoListState()
        state.phase = .loaded
        state.nextPageURL = nil  // no more pages

        let result = reduce(state, .loadMore)

        XCTAssertEqual(result.phase, .loaded)  // unchanged
    }

    func test_loadMore_isIgnored_whenAlreadyFetching() {
        var state = RepoListState()
        state.phase = .loadingInitial
        state.nextPageURL = URL(string: "https://api.github.com/repositories?since=100")

        let result = reduce(state, .loadMore)

        XCTAssertEqual(result.phase, .loadingInitial)  // unchanged
    }

    // MARK: - repositoriesLoaded

    func test_repositoriesLoaded_appendsReposAndSetsLoadedPhase() {
        var state = RepoListState()
        state.repositories = [.mockOriginal]
        state.phase = .loadingInitial
        let nextURL = URL(string: "https://api.github.com/repositories?since=204")

        let result = reduce(state, .repositoriesLoaded([.mockFork, .mockOrgRepo], nextURL: nextURL))

        XCTAssertEqual(result.repositories.count, 3)
        XCTAssertEqual(result.repositories.last?.id, Repository.mockOrgRepo.id)
        XCTAssertEqual(result.nextPageURL, nextURL)
        XCTAssertEqual(result.phase, .loaded)
    }

    func test_repositoriesLoaded_setsNilNextURL_whenLastPage() {
        var state = RepoListState()
        state.phase = .loadingMore

        let result = reduce(state, .repositoriesLoaded([.mockOriginal], nextURL: nil))

        XCTAssertNil(result.nextPageURL)
        XCTAssertFalse(result.hasMorePages)
    }

    // MARK: - fetchDetails

    func test_fetchDetails_setsFetchingDetailsPhase() {
        var state = RepoListState()
        state.phase = .loaded

        let result = reduce(state, .fetchDetails)

        XCTAssertEqual(result.phase, .fetchingDetails)
    }

    // MARK: - detailsLoaded

    func test_detailsLoaded_enrichesMatchingReposAndSetsLoadedPhase() {
        var state = RepoListState()
        state.repositories = [.mockOriginal, .mockFork]
        state.phase = .fetchingDetails
        let detailMap = [Repository.mockOriginal.fullName: RepositoryDetail.mockBasic]

        let result = reduce(state, .detailsLoaded(detailMap))

        XCTAssertEqual(result.phase, .loaded)
        // mockOriginal is enriched
        let enriched = result.repositories.first { $0.id == Repository.mockOriginal.id }
        XCTAssertEqual(enriched?.stargazersCount, RepositoryDetail.mockBasic.stargazersCount)
        XCTAssertEqual(enriched?.language, RepositoryDetail.mockBasic.language)
        // mockFork is unchanged — not in detailMap
        let unchanged = result.repositories.first { $0.id == Repository.mockFork.id }
        XCTAssertEqual(unchanged?.stargazersCount, Repository.mockFork.stargazersCount)
    }

    // MARK: - repositoryEnriched

    func test_repositoryEnriched_updatesCorrectRepoInPlace() {
        var state = RepoListState()
        state.repositories = [.mockOriginal, .mockFork, .mockOrgRepo]

        let enriched = Repository.mockOriginal.merging(detail: .mockBasic)
        let result   = reduce(state, .repositoryEnriched(enriched))

        let updated = result.repositories.first { $0.id == enriched.id }
        XCTAssertEqual(updated?.stargazersCount, RepositoryDetail.mockBasic.stargazersCount)
        // Other repos untouched
        XCTAssertEqual(result.repositories.count, 3)
    }

    func test_repositoryEnriched_returnsUnchangedState_whenRepoNotFound() {
        let state = RepoListState()
        let result = reduce(state, .repositoryEnriched(.mockOriginal))

        XCTAssertEqual(result, state)
    }

    // MARK: - fetchFailed

    func test_fetchFailed_setsErrorPhase() {
        var state = RepoListState()
        state.phase = .loadingInitial

        let result = reduce(state, .fetchFailed("Rate limited"))

        XCTAssertEqual(result.phase, .error("Rate limited"))
    }

    // MARK: - changeGrouping

    func test_changeGrouping_updatesGroupingOption() {
        let state = RepoListState()
        let result = reduce(state, .changeGrouping(.forkStatus))

        XCTAssertEqual(result.groupingOption, .forkStatus)
    }

    // MARK: - toggleGroup

    func test_toggleGroup_collapsesExpandedGroup() {
        var state = RepoListState()
        state.collapsedGroups = []

        let result = reduce(state, .toggleGroup("User"))

        XCTAssertTrue(result.collapsedGroups.contains("User"))
    }

    func test_toggleGroup_expandsCollapsedGroup() {
        var state = RepoListState()
        state.collapsedGroups = ["User"]

        let result = reduce(state, .toggleGroup("User"))

        XCTAssertFalse(result.collapsedGroups.contains("User"))
    }

    // MARK: - toggleBookmark

    func test_toggleBookmark_insertsID_whenBookmarking() {
        let state = RepoListState()
        let result = reduce(state, .toggleBookmark(.mockOriginal, isBookmarked: true))

        XCTAssertTrue(result.bookmarkedIDs.contains(Repository.mockOriginal.id))
    }

    func test_toggleBookmark_removesID_whenUnbookmarking() {
        var state = RepoListState()
        state.bookmarkedIDs = [Repository.mockOriginal.id]

        let result = reduce(state, .toggleBookmark(.mockOriginal, isBookmarked: false))

        XCTAssertFalse(result.bookmarkedIDs.contains(Repository.mockOriginal.id))
    }

    // MARK: - syncBookmark

    func test_syncBookmark_replacesEntireBookmarkedIDSet() {
        var state = RepoListState()
        state.bookmarkedIDs = [1, 2, 3]
        let newIDs: Set<Int> = [Repository.mockOriginal.id, Repository.mockFork.id]

        let result = reduce(state, .syncBookmark(newIDs))

        XCTAssertEqual(result.bookmarkedIDs, newIDs)
    }
}
