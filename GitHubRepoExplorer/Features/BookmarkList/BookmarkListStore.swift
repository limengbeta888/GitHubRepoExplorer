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

    private var cancellables = Set<AnyCancellable>()
    private let bookmarkService: BookmarkServiceProtocol

    init(bookmarkService: BookmarkServiceProtocol? = nil) {
        self.bookmarkService = bookmarkService ?? BookmarkService.shared
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
