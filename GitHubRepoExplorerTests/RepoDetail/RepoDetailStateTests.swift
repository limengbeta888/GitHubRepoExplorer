//
//  RepoDetailStateTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

import XCTest
@testable import GitHubRepoExplorer

@MainActor
final class RepoDetailStateTests: XCTestCase {

    func test_init_setsIdlePhase_whenStargazersCountIsNil() {
        let state = RepoDetailState(repository: .mockOriginal)  // stargazersCount == nil
        XCTAssertEqual(state.phase, .idle)
    }

    func test_init_setsLoadedPhase_whenRepoAlreadyEnriched() {
        let state = RepoDetailState(repository: .mockFork)  // stargazersCount != nil
        XCTAssertEqual(state.phase, .loaded)
    }

    func test_init_setsIsBookmarkedFalse_byDefault() {
        let state = RepoDetailState(repository: .mockOriginal)
        XCTAssertFalse(state.isBookmarked)
    }
}
