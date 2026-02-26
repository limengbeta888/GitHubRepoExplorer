//
//  BookmarkListStore.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation
import Combine

@MainActor
final class BookmarkListStore: ObservableObject {
    @Published var state: BookmarkListState = .init()

    let container: DependencyContainer
    private let gitHubService: GitHubServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let repositoryUpdateService: RepositoryUpdateServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()

    init(container: DependencyContainer) {
        self.container = container
        self.gitHubService = container.retrieve(.github) as! GitHubServiceProtocol
        self.bookmarkService = container.retrieve(.bookmark) as! BookmarkServiceProtocol
        self.repositoryUpdateService = container.retrieve(.repositoryUpdate) as! RepositoryUpdateServiceProtocol
        
        subscribeToService()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Dispatch

    func dispatch(_ intent: BookmarkListIntent) {
        state = BookmarkListReducer.reduce(state, intent: intent)

        switch intent {
        case .loadBookmarks:
            bookmarkService.loadAllBookmarks()

        case .removeBookmark(let repo):
            bookmarkService.removeBookmark(repo)

        case .updateEnriched(let repos):
            repos.forEach { bookmarkService.updateBookmark($0) }

        case .bookmarksLoaded:
            break
        }
    }
  
    // MARK: - Private

    private func subscribeToService() {
        bookmarkService.bookmarksLoadedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repos in
                self?.dispatch(.bookmarksLoaded(repos))
            }
            .store(in: &cancellables)
    }
}
