//
//  RepoListState.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

struct RepoListState: Equatable {
    var repos: [Repository] = []
    var isLoading: Bool = false
    var hasMore: Bool = true
    var errorMessage: String? = nil
}
