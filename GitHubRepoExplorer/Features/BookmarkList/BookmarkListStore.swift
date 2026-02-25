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
    static let shared = BookmarkListStore()

    @Published var state: BookmarkListState = .init()

    private var cancellables = Set<AnyCancellable>()
    private let bookmarkService: BookmarkServiceProtocol

    init(bookmarkService: BookmarkServiceProtocol? = nil) {
        self.bookmarkService = bookmarkService ?? BookmarkService.shared
        subscribeToService()
        dispatch(.loadBookmarks)
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

        bookmarkService.bookmarkRemovedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repo in
                self?.dispatch(.removeBookmark(repo))
            }
            .store(in: &cancellables)

        bookmarkService.bookmarkUpdatedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repo in
                self?.dispatch(.updateEnriched([repo]))
            }
            .store(in: &cancellables)
    }
    
//    // MARK: - Subscribers
//    
//    private func subscribeToEvents() {
//        AppEventBus.shared.events
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] event in
//                guard let self else { return }
//                
//                switch event {
//                case .bookmarkToggled(let repo, let isBookmarked):
//                    dispatch(isBookmarked ? .bookmark(repo) : .removeBookmark(repo))
//                    
//                case .repositoryEnriched(let repo):
//                    dispatch(.updateEnriched([repo]))
//                }
//            }
//            .store(in: &cancellables)
//    }
}
