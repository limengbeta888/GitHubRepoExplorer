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
        loadFromDisk()
    }

    // MARK: - Dispatch
    
    func dispatch(_ intent: BookmarkListIntent) {
        state = BookmarkListReducer.reduce(state, intent: intent)

        switch intent {
        case .bookmark(let repo):
            try? persistence.add(repo)

        case .removeBookmark(let repo):
            try? persistence.remove(repo)

        case .updateEnriched(let repos):
            repos.forEach { try? persistence.update($0) }

        case .loadBookmarks:
            break
        }
    }

    // MARK: - Private

    private func loadFromDisk() {
        let repos = (try? persistence.loadAll()) ?? []
        state = BookmarkListReducer.reduce(state, intent: .loadBookmarks(repos))
    }
}
