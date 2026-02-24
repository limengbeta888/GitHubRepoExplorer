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
    var searchText: String = ""

    var filteredRepos: [Repository] {
        guard !searchText.isEmpty else { return bookmarkedRepos }
        let q = searchText.lowercased()
        return bookmarkedRepos.filter {
            $0.name.lowercased().contains(q) ||
            $0.owner.login.lowercased().contains(q) ||
            ($0.description?.lowercased().contains(q) == true)
        }
    }

    func isBookmarked(_ repo: Repository) -> Bool {
        bookmarkedIDs.contains(repo.id)
    }
}
