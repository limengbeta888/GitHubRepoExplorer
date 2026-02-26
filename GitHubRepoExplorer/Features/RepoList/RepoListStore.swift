//
//  RepoListStore.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class RepoListStore: ObservableObject {
    @Published private(set) var state = RepoListState()

    private let gitHubService: GitHubServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let repositoryUpdateService: RepositoryUpdateServiceProtocol
    
    private var fetchTask: Task<Void, Never>?
    private var detailTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()
    
    // nil defaults resolved inside init — avoids referencing actor-isolated
    // state in a nonisolated default argument expression.
    init(
        gitHubService: GitHubServiceProtocol? = nil,
        bookmarkService: BookmarkServiceProtocol? = nil,
        repositoryUpdateService: RepositoryUpdateServiceProtocol? = nil
    ) {
        self.gitHubService = gitHubService ?? GitHubService.shared
        self.bookmarkService = bookmarkService ?? BookmarkService.shared
        self.repositoryUpdateService = repositoryUpdateService ?? RepositoryUpdateService.shared
        
        subscribeToService()
    }

    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Dispatch

    func dispatch(_ intent: RepoListIntent) {
        state = RepoListReducer.reduce(state, intent: intent)

        switch intent {
        case .loadInitial:
            guard state.phase == .loadingInitial else { return }
            fetchTask?.cancel()
            fetchTask = Task { [weak self] in
                guard let self else { return }
                await self.fetchPage()
            }

        case .loadMore:
            guard state.phase == .loadingMore, state.nextPageURL != nil else { return }
            fetchTask?.cancel()
            fetchTask = Task { [weak self] in
                guard let self else { return }
                await self.fetchPage()
            }

        case .changeGrouping(let option):
            if option.requiresDetail {
                triggerDetailFetchIfNeeded()
            }

        case .fetchDetails:
            // To fetch the information of languages and stargazers
            detailTask?.cancel()
            detailTask = Task { [weak self] in
                guard let self else { return }
                let detailMap = await self.gitHubService.fetchDetails(for: state.repositories.filter { $0.stargazersCount == nil })
                self.dispatch(.detailsLoaded(detailMap))
            }
            
        case .repositoriesLoaded:
            if state.groupingOption.requiresDetail {
                triggerDetailFetchIfNeeded()
            }

        case .detailsLoaded(let detailMap):
            // Enrich any persisted bookmarks that just received stars/language
            // so the Bookmarks tab shows up-to-date data without re-fetching.
            enrichPersistedBookmarks(with: detailMap)
        
        case .toggleBookmark(let repo, let isBookmarked):
            if isBookmarked {
                bookmarkService.addBookmark(repo)
            } else {
                bookmarkService.removeBookmark(repo)
            }
        
        case .fetchFailed, .toggleGroup, .syncBookmark, .repositoryEnriched:
            break
        }
    }

    // MARK: - Subscribers
    
    private func subscribeToService() {
        bookmarkService.bookmarksLoadedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.dispatch(.syncBookmark(self.bookmarkService.cachedBookmarkedIDs))
            }
            .store(in: &cancellables)
        
        bookmarkService.bookmarkAdded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.dispatch(.syncBookmark(self.bookmarkService.cachedBookmarkedIDs))
            }
            .store(in: &cancellables)

        bookmarkService.bookmarkRemoved
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.dispatch(.syncBookmark(self.bookmarkService.cachedBookmarkedIDs))
            }
            .store(in: &cancellables)
        
        repositoryUpdateService.repositoryEnriched
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repo in
                 guard let self else { return }
                 self.dispatch(.repositoryEnriched(repo))
             }
             .store(in: &cancellables)
    }
    
    // MARK: - Private side effects

    private func fetchPage() async {
        do {
            let result: (repos: [Repository], nextURL: URL?)
            if let nextURL = state.nextPageURL {
                result = try await gitHubService.fetchNextRepositories(url: nextURL)
            } else {
                result = try await gitHubService.fetchRepositories()
            }
            dispatch(.repositoriesLoaded(result.repos, nextURL: result.nextURL))
        } catch {
            dispatch(.fetchFailed(error.localizedDescription))
        }
    }
    
    private func triggerDetailFetchIfNeeded() {
        let missing = state.repositories.filter { $0.stargazersCount == nil }
        guard !missing.isEmpty else { return }
        
        dispatch(.fetchDetails)
    }

    private func enrichPersistedBookmarks(with detailMap: [String: RepositoryDetail]) {
        let saved = bookmarkService.cachedBookmarks
        saved.forEach { repo in
            guard let detail = detailMap[repo.fullName] else { return }
            bookmarkService.updateBookmark(repo.merging(detail: detail))
        }
    }
}
