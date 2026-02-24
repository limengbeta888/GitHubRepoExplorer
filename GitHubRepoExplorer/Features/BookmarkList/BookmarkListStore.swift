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
        self.persistence = persistence ?? UserDefaultsPersistenceService.shared
        loadFromDisk()
    }

    // MARK: - Dispatch

    func dispatch(_ intent: BookmarkListIntent) {
        let newState = BookmarkListReducer.reduce(state, intent: intent)

        // Write to disk only when the persisted set actually changes
        if newState.bookmarkedRepos != state.bookmarkedRepos {
            try? persistence.save(newState.bookmarkedRepos, forKey: .bookmarkedRepositories)
        }

        state = newState
    }

    // MARK: - Private

    private func loadFromDisk() {
        let repos: [Repository] = (try? persistence.load(forKey: .bookmarkedRepositories)) ?? []
        state = BookmarkListReducer.reduce(state, intent: .loadBookmarks(repos))
    }
}
