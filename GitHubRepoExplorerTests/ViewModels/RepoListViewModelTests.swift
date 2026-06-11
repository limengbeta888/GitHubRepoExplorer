//
//  RepoListViewModelTests.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import Testing
import Foundation
import Combine
import SwiftUI
@testable import GitHubRepoExplorer

@MainActor
@Suite("RepoListViewModel Tests")
struct RepoListViewModelTests {
    
    private func setupContainer(behaviour: MockGitHubService.Behaviour = .success) -> DependencyContainer {
        let container = DependencyContainer(
            githubService: MockGitHubService(behaviour: behaviour),
            bookmarkService: MockBookmarkService(behaviour: .noBookmarks),
            repositoryUpdateService: MockRepositoryUpdateService()
        )
        return container
    }

    @Test("Initial state is correct")
    func initialState() {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        #expect(viewModel.phase == .idle)
        #expect(viewModel.repositories.isEmpty)
        #expect(viewModel.collapsedGroups.isEmpty)
    }

    @Test("Load initial repositories successfully")
    func loadInitialSuccess() async throws {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        viewModel.loadInitial()
        #expect(viewModel.phase == .loadingInitial)
        
        // Await the internal task instead of sleeping
        await viewModel.fetchTask?.value
        
        #expect(viewModel.phase == .loaded)
        #expect(!viewModel.repositories.isEmpty)
        #expect(viewModel.nextPageURL != nil)
    }

    @Test("Load initial repositories failure")
    func loadInitialFailure() async throws {
        let container = setupContainer(behaviour: .networkError)
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        viewModel.loadInitial()
        await viewModel.fetchTask?.value
        
        if case .error(let msg) = viewModel.phase {
            #expect(!msg.isEmpty)
        } else {
            Issue.record("Expected error phase, but got \(viewModel.phase)")
        }
    }

    @Test("Changing grouping triggers detail fetch if needed")
    func changeGroupingTriggersDetailFetch() async throws {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        // 1. Load initial
        viewModel.loadInitial()
        await viewModel.fetchTask?.value
        #expect(viewModel.phase == .loaded)
        
        // 2. Change grouping to language (requires details)
        viewModel.changeGrouping(.language)
        
        // Assignment of phase = .fetchingDetails happens synchronously on MainActor
        #expect(viewModel.phase == .fetchingDetails)
        
        // 3. Await the detail fetch task
        await viewModel.detailTask?.value
        #expect(viewModel.phase == .loaded)
    }

    @Test("Load more repositories successfully")
    func loadMoreSuccess() async throws {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        // 1. Initial load
        viewModel.loadInitial()
        await viewModel.fetchTask?.value
        let initialCount = viewModel.repositories.count
        
        // 2. Load more
        #expect(viewModel.hasMorePages)
        viewModel.loadMore()
        #expect(viewModel.phase == .loadingMore)
        
        await viewModel.fetchTask?.value
        #expect(viewModel.repositories.count > initialCount)
        #expect(viewModel.phase == .loaded)
    }

    @Test("Toggle group collapse/expand")
    func toggleGroup() async throws {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        viewModel.loadInitial()
        await viewModel.fetchTask?.value
        
        guard let firstGroup = viewModel.groupedRepositories.first?.key else {
            Issue.record("No groups found")
            return
        }
        
        #expect(!viewModel.collapsedGroups.contains(firstGroup))
        
        viewModel.toggleGroup(firstGroup)
        #expect(viewModel.collapsedGroups.contains(firstGroup))
        
        viewModel.toggleGroup(firstGroup)
        #expect(!viewModel.collapsedGroups.contains(firstGroup))
    }

    @Test("Toggle bookmark updates local state and service")
    func toggleBookmark() async throws {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        viewModel.loadInitial()
        await viewModel.fetchTask?.value
        
        let repo = viewModel.repositories[0]
        #expect(!viewModel.bookmarkedIDs.contains(repo.id))
        
        // Add bookmark
        viewModel.toggleBookmark(repo, isBookmarked: true)
        #expect(viewModel.bookmarkedIDs.contains(repo.id))
        #expect(container.bookmarkService.cachedBookmarkedIDs.contains(repo.id))
        
        // Remove bookmark
        viewModel.toggleBookmark(repo, isBookmarked: false)
        #expect(!viewModel.bookmarkedIDs.contains(repo.id))
        #expect(!container.bookmarkService.cachedBookmarkedIDs.contains(repo.id))
    }

    @Test("Reactive update from repository enrichment service")
    func reactiveEnrichmentUpdate() async throws {
        let container = setupContainer()
        let coordinator = RepoCoordinator(container: container)
        let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
        
        viewModel.loadInitial()
        await viewModel.fetchTask?.value
        
        let repo = viewModel.repositories[0]
        #expect(repo.stargazersCount == nil)
        
        // Simulate external enrichment
        let enrichedRepo = repo.merging(detail: RepositoryDetail.mockBasic)
        container.repositoryUpdateService.publishEnrichment(enrichedRepo)
        
        // The Combine subscription updates the array synchronously on the main thread 
        // because of .receive(on: DispatchQueue.main) it might be pushed to the next runloop.
        // However, we can use Task.yield() or a very short wait to be safe, 
        // but better is to ensure it is handled.
        
        // Let's wait for the next main actor cycle
        await Task.yield()
        
        #expect(viewModel.repositories[0].stargazersCount == RepositoryDetail.mockBasic.stargazersCount)
    }
}
