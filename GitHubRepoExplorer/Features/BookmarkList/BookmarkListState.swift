//
//  BookmarkListState.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

struct BookmarkListState: Equatable {
    var bookmarkedRepos: [Repository] = []
    var bookmarkedIDs: Set<Int> = []

    func isBookmarked(_ repo: Repository) -> Bool {
        bookmarkedIDs.contains(repo.id)
    }
}
