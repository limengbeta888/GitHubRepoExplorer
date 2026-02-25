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

    private let persistence: PersistenceServiceProtocol

    init(persistence: PersistenceServiceProtocol? = nil) {
        self.persistence = persistence ?? PersistenceService.shared
        dispatch(.loadBookmarks)
    }

    // MARK: - Dispatch
    
    func dispatch(_ intent: BookmarkListIntent) {
        state = BookmarkListReducer.reduce(state, intent: intent)

        switch intent {
        case .loadBookmarks:
            let repos = (try? persistence.loadAllRepos()) ?? []
            dispatch(.bookmarksLoaded(repos))
            
        case .bookmark(let repo):
            try? persistence.add(repo)

        case .removeBookmark(let repo):
            try? persistence.remove(repo)

        case .updateEnriched(let repos):
            repos.forEach { try? persistence.update($0) }

        case .bookmarksLoaded:
            break
        }
    }
}
