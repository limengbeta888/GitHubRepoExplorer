//
//  RepoDetailStore.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation
import Combine

@MainActor
final class RepoDetailStore: ObservableObject {
    @Published var state: RepoDetailState

    private var detailTask: Task<Void, Never>?
    
    private let githubService: GitHubServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let repositoryUpdateService: RepositoryUpdateServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // nil defaults resolved inside init — avoids referencing actor-isolated
    // state in a nonisolated default argument expression.
    init(
        repo: Repository,
        githubService: GitHubServiceProtocol? = nil,
        bookmarkService: BookmarkServiceProtocol? = nil,
        repositoryUpdateService: RepositoryUpdateServiceProtocol? = nil
    ) {
        self.state = RepoDetailState(repository: repo)
        self.githubService = githubService ?? GitHubService.shared
        self.bookmarkService = bookmarkService ?? BookmarkService.shared
        self.repositoryUpdateService = repositoryUpdateService ?? RepositoryUpdateService.shared
        
        subscribeToService(repo: repo)
        
        let bookmarkSvc = bookmarkService ?? BookmarkService.shared
        let isBookmarked = bookmarkSvc.cachedBookmarkedIDs.contains(repo.id)
        dispatch(.syncBookmark(isBookmarked: isBookmarked))
    }

    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Dispatch

    func dispatch(_ intent: RepoDetailIntent) {
        state = RepoDetailReducer.reduce(state, intent: intent)

        switch intent {
        case .loadDetail:
            guard state.phase == .loadingDetail else { return }
            
            detailTask?.cancel()
            detailTask = Task { [weak self] in
                guard let self else { return }
                await self.fetchDetail()
            }
            
        case .toggleBookmark:
            if state.isBookmarked {
                bookmarkService.addBookmark(state.repository)
            } else {
                bookmarkService.removeBookmark(state.repository)
            }

        case .detailLoaded:
            repositoryUpdateService.publishEnrichment(state.repository)
            
        case .syncBookmark, .fetchFailed:
            break
        }
    }

    // MARK: - Private side effects

    private func fetchDetail() async {
        do {
            let detail = try await githubService.fetchDetail(for: state.repository)
            dispatch(.detailLoaded(detail))
        } catch {
            dispatch(.fetchFailed(error.localizedDescription))
        }
    }

    /// Keeps bookmark icon in sync if toggled from another screen (e.g. RepoListView swipe)
    private func subscribeToService(repo: Repository) {
        bookmarkService.bookmarkAdded
            .filter { $0.id == repo.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dispatch(.syncBookmark(isBookmarked: true))
            }
            .store(in: &cancellables)

        bookmarkService.bookmarkRemoved
            .filter { $0.id == repo.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dispatch(.syncBookmark(isBookmarked: false))
            }
            .store(in: &cancellables)
    }
}
