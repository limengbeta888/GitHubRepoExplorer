//
//  BookmarkListReducer.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum BookmarkListReducer {

    static func reduce(_ state: BookmarkListState, intent: BookmarkListIntent) -> BookmarkListState {
        var next = state

        switch intent {
        case .loadBookmarks:
            break
            
        case .bookmarksLoaded(let repos):
            next.bookmarkedRepos = repos

        case .removeBookmark(let repo):
            next.bookmarkedRepos.removeAll { $0.id == repo.id }

        case .updateEnriched(let enriched):
            let map = Dictionary(uniqueKeysWithValues: enriched.map { ($0.id, $0) })
            next.bookmarkedRepos = state.bookmarkedRepos.map { map[$0.id] ?? $0 }
            // bookmarkedIDs unchanged — no need to recompute
        }

        return next
    }
}
