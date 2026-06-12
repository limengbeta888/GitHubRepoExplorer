//
//  RepoDetailViewModelTests.swift
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
@Suite("RepoDetailViewModel Tests", .serialized)
struct RepoDetailViewModelTests {
    
    private func setupContainer(behaviour: MockGitHubService.Behaviour = .success) -> DependencyContainer {
        let container = DependencyContainer(
            githubService: MockGitHubService(behaviour: behaviour),
            bookmarkService: MockBookmarkService(behaviour: .noBookmarks),
            repositoryUpdateService: MockRepositoryUpdateService()
        )
        return container
    }

    @Test("Initial state is correct for non-enriched repository")
    func initialStateUnenriched() {
        let container = setupContainer()
        let repo = Repository.mockOriginal // No stargazersCount
        let viewModel = RepoDetailViewModel(repository: repo, container: container)
        
        #expect(viewModel.phase == .idle)
        #expect(viewModel.isBookmarked == false)
        #expect(viewModel.repository.id == repo.id)
    }

    @Test("Initial state is correct for already enriched repository")
    func initialStateEnriched() {
        let container = setupContainer()
        let repo = Repository.mockOrgRepo // Has stargazersCount
        let viewModel = RepoDetailViewModel(repository: repo, container: container)
        
        #expect(viewModel.phase == .loaded)
    }

    @Test("Load detail successfully enriches repository and notifies app")
    func loadDetailSuccess() async throws {
        let container = setupContainer()
        let repo = Repository.mockOriginal
        let viewModel = RepoDetailViewModel(repository: repo, container: container)
        
        viewModel.loadDetail()
        #expect(viewModel.phase == .loadingDetail)
        
        await viewModel.detailTask?.value
        
        #expect(viewModel.phase == .loaded)
        #expect(viewModel.repository.stargazersCount != nil)
        #expect(viewModel.repository.stargazersCount == RepositoryDetail.mockBasic.stargazersCount)
    }

    @Test("Load detail failure sets error phase")
    func loadDetailFailure() async throws {
        let container = setupContainer(behaviour: .networkError)
        let repo = Repository.mockOriginal
        let viewModel = RepoDetailViewModel(repository: repo, container: container)
        
        viewModel.loadDetail()
        await viewModel.detailTask?.value
        
        if case .error(let msg) = viewModel.phase {
            #expect(!msg.isEmpty)
        } else {
            Issue.record("Expected error phase")
        }
    }

    @Test("Toggle bookmark updates state and notifies service")
    func toggleBookmark() {
        let container = setupContainer()
        let repo = Repository.mockOriginal
        let viewModel = RepoDetailViewModel(repository: repo, container: container)
        
        #expect(viewModel.isBookmarked == false)
        
        // Add
        viewModel.toggleBookmark()
        #expect(viewModel.isBookmarked == true)
        #expect(container.bookmarkService.cachedBookmarkedIDs.contains(repo.id))
        
        // Remove
        viewModel.toggleBookmark()
        #expect(viewModel.isBookmarked == false)
        #expect(!container.bookmarkService.cachedBookmarkedIDs.contains(repo.id))
    }

    @Test("Reactive update when repository is bookmarked elsewhere")
    func reactiveBookmarkUpdate() async throws {
        let container = setupContainer()
        let repo = Repository.mockOriginal
        let viewModel = RepoDetailViewModel(repository: repo, container: container)
        
        #expect(viewModel.isBookmarked == false)
        
        // Simulate bookmarking from a different part of the app
        container.bookmarkService.addBookmark(repo)
        
        // Wait for Combine subscription
        await Task.yield()
        
        #expect(viewModel.isBookmarked == true)
        
        // Simulate removal
        container.bookmarkService.removeBookmark(repo)
        await Task.yield()
        
        #expect(viewModel.isBookmarked == false)
    }
}
