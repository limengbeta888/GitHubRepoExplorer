//
//  RepoListStateTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
@testable import GitHubRepoExplorer

// Tests for computed properties on RepoListState.

@MainActor
final class RepoListStateTests: XCTestCase {

    // MARK: - hasMorePages

    @MainActor
    func test_hasMorePages_isTrue_whenNextPageURLIsSet() {
        var state = RepoListState()
        state.nextPageURL = URL(string: "https://api.github.com/repositories?since=100")

        XCTAssertTrue(state.hasMorePages)
    }

    @MainActor
    func test_hasMorePages_isFalse_whenNextPageURLIsNil() {
        let state = RepoListState()
        XCTAssertFalse(state.hasMorePages)
    }

    // MARK: - isFetching

    @MainActor
    func test_isFetching_isTrue_duringLoadingInitial() {
        var state = RepoListState()
        state.phase = .loadingInitial
        XCTAssertTrue(state.isFetching)
    }

    @MainActor
    func test_isFetching_isTrue_duringLoadingMore() {
        var state = RepoListState()
        state.phase = .loadingMore
        XCTAssertTrue(state.isFetching)
    }

    @MainActor
    func test_isFetching_isFalse_whenLoaded() {
        var state = RepoListState()
        state.phase = .loaded
        XCTAssertFalse(state.isFetching)
    }

    // MARK: - hasVisibleRows

    @MainActor
    func test_hasVisibleRows_isTrue_whenAtLeastOneGroupExpanded() {
        var state = RepoListState()
        state.repositories = [.mockOriginal, .mockOrgRepo]
        state.groupingOption = .ownerType
        state.collapsedGroups = ["Organization"]  // User group still expanded

        XCTAssertTrue(state.hasVisibleRows)
    }

    @MainActor
    func test_hasVisibleRows_isFalse_whenAllGroupsCollapsed() {
        var state = RepoListState()
        state.repositories = [.mockOriginal, .mockOrgRepo]
        state.groupingOption = .ownerType
        state.collapsedGroups = ["User", "Organization"]

        XCTAssertFalse(state.hasVisibleRows)
    }

    // MARK: - groupedRepositories

    @MainActor
    func test_groupedRepositories_groupsByOwnerType() {
        var state = RepoListState()
        state.repositories = [.mockOriginal, .mockFork, .mockOrgRepo]
        state.groupingOption = .ownerType

        let groups = state.groupedRepositories

        let userGroup = groups.first { $0.key == "User" }
        let orgGroup  = groups.first { $0.key == "Organization" }
        XCTAssertNotNil(userGroup)
        XCTAssertNotNil(orgGroup)
        XCTAssertEqual(userGroup?.repos.count, 2)  // mockOriginal + mockFork
        XCTAssertEqual(orgGroup?.repos.count, 1)   // mockOrgRepo
    }

    @MainActor
    func test_groupedRepositories_groupsByForkStatus() {
        var state = RepoListState()
        state.repositories = [.mockOriginal, .mockFork, .mockOrgRepo]
        state.groupingOption = .forkStatus

        let groups = state.groupedRepositories

        let forkedGroup = groups.first { $0.key == "Forked" }
        let originalGroup = groups.first { $0.key == "Original" }
        XCTAssertEqual(forkedGroup?.repos.count, 1)    // mockFork
        XCTAssertEqual(originalGroup?.repos.count, 2)  // mockOriginal + mockOrgRepo
    }

    @MainActor
    func test_groupedRepositories_sortsByStargazerBandDescending_whenGroupingByStars() {
        var state = RepoListState()
        state.repositories = [.mockZeroStars, .mockStars1000plus, .mockStars1to9]
        state.groupingOption = .stargazers

        let groups = state.groupedRepositories

        // Highest stars band should come first
        XCTAssertEqual(groups.first?.key, Repository.mockStars1000plus.stargazerBand)
        XCTAssertEqual(groups.last?.key, Repository.mockZeroStars.stargazerBand)
    }

    @MainActor
    func test_groupedRepositories_isSortedAlphabetically_forNonStarGroupings() {
        var state = RepoListState()
        state.repositories   = [.mockOrgRepo, .mockOriginal]  // Org before User
        state.groupingOption = .ownerType

        let groups = state.groupedRepositories
        let keys = groups.map(\.key)

        XCTAssertEqual(keys, keys.sorted())
    }
}
