//
//  RepoListViewModelTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import Testing
import Foundation
import Combine
@testable import GitHubRepoExplorer

@MainActor
struct RepoListViewModelTests {
    
    private func setupContainer() -> DependencyContainer {
        let container = DependencyContainer(
            githubService: MockGitHubService(behaviour: .success),
            bookmarkService: MockBookmarkService(behaviour: .noBookmarks),
            repositoryUpdateService: MockRepositoryUpdateService()
        )
        return container
    }

    @Test("Load initial repositories successfully")
    func loadInitialSuccess() async throws {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        #expect(viewModel.phase == .idle)
        
        viewModel.loadInitial()
        #expect(viewModel.phase == .loadingInitial)
        
        try await viewModel.waitForPhase(.loaded)
        
        #expect(viewModel.phase == .loaded)
        #expect(!viewModel.repositories.isEmpty)
        #expect(viewModel.nextPageURL != nil)
    }

    @Test("Load initial repositories failure")
    func loadInitialFailure() async throws {
        let container = setupContainer()
        container.register(githubService: MockGitHubService(behaviour: .networkError))
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        viewModel.loadInitial()
        
        try await viewModel.waitForPhase { if case .error = $0 { return true }; return false }
        
        if case .error(let msg) = viewModel.phase {
            #expect(!msg.isEmpty)
        } else {
            Issue.record("Expected error phase")
        }
    }

    @Test("Changing grouping triggers detail fetch if needed")
    func changeGroupingTriggersDetailFetch() async throws {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        viewModel.loadInitial()
        try await viewModel.waitForPhase(.loaded)
        
        viewModel.changeGrouping(.language)
        
        #expect(viewModel.phase == .fetchingDetails)
        try await viewModel.waitForPhase(.loaded)
        #expect(viewModel.phase == .loaded)
    }
}

// MARK: - Helpers

extension RepoListViewModel {
    func waitForPhase(_ expectedPhase: RepoListViewModel.Phase) async throws {
        try await waitForPhase { $0 == expectedPhase }
    }
    
    func waitForPhase(_ condition: @escaping (RepoListViewModel.Phase) -> Bool) async throws {
        let timeout = Date().addingTimeInterval(2.0)
        while !condition(self.phase) && Date() < timeout {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        if !condition(self.phase) {
            throw TimeoutError()
        }
    }
    
    struct TimeoutError: Error {}
}
