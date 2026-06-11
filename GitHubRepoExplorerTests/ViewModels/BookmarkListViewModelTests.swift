//
//  BookmarkListViewModelTests.swift
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
@Suite("BookmarkListViewModel Tests")
struct BookmarkListViewModelTests {
    
    private func setupContainer(behaviour: MockBookmarkService.Behaviour = .hasBookmarks) -> DependencyContainer {
        let container = DependencyContainer(
            githubService: MockGitHubService(),
            bookmarkService: MockBookmarkService(behaviour: behaviour),
            repositoryUpdateService: MockRepositoryUpdateService()
        )
        return container
    }

    @Test("Load bookmarks updates repository list")
    func loadBookmarks() async throws {
        let container = setupContainer(behaviour: .hasBookmarks)
        let coordinator = BookmarkCoordinator(container: container)
        let viewModel = BookmarkListViewModel(container: container, coordinator: coordinator)
        
        #expect(viewModel.bookmarkedRepos.isEmpty)
        
        viewModel.loadBookmarks()
        
        // Combine publisher on MainActor needs a yield
        await Task.yield()
        
        #expect(!viewModel.bookmarkedRepos.isEmpty)
        #expect(viewModel.bookmarkedRepos.count > 0)
    }

    @Test("Remove bookmark updates local state")
    func removeBookmark() async throws {
        let container = setupContainer(behaviour: .hasBookmarks)
        let coordinator = BookmarkCoordinator(container: container)
        let viewModel = BookmarkListViewModel(container: container, coordinator: coordinator)
        
        viewModel.loadBookmarks()
        await Task.yield()
        
        let initialCount = viewModel.bookmarkedRepos.count
        let repoToRemove = viewModel.bookmarkedRepos[0]
        
        viewModel.removeBookmark(repoToRemove)
        
        // The service notifies back via bookmarkRemoved, which triggers loadBookmarks()
        await Task.yield()
        
        #expect(viewModel.bookmarkedRepos.count == initialCount - 1)
        #expect(!viewModel.bookmarkedRepos.contains(where: { $0.id == repoToRemove.id }))
    }

    @Test("Reactive response to adding a bookmark")
    func reactiveAddBookmark() async throws {
        let container = setupContainer(behaviour: .noBookmarks)
        let coordinator = BookmarkCoordinator(container: container)
        let viewModel = BookmarkListViewModel(container: container, coordinator: coordinator)
        
        // Initially empty
        viewModel.loadBookmarks()
        await Task.yield()
        #expect(viewModel.bookmarkedRepos.isEmpty)
        
        // Simulate adding a bookmark from elsewhere (e.g. RepoDetail)
        let newRepo = Repository.mockOriginal
        container.bookmarkService.addBookmark(newRepo)
        
        // ViewModel observes bookmarkService.bookmarkAdded and reloads
        await Task.yield()
        
        #expect(viewModel.bookmarkedRepos.count == 1)
        #expect(viewModel.bookmarkedRepos[0].id == newRepo.id)
    }

    @Test("Navigate to detail screen")
    func navigateToDetail() async throws {
        let container = setupContainer()
        let coordinator = BookmarkCoordinator(container: container)
        let viewModel = BookmarkListViewModel(container: container, coordinator: coordinator)
        
        let repo = Repository.mockOriginal
        viewModel.showDetail(for: repo)
        
        // Verify coordinator path changed
        #expect(!coordinator.path.isEmpty)
    }
}
