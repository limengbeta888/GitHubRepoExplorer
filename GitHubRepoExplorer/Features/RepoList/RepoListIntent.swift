//
//  RepoListIntent.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum RepoListIntent {

    // User actions
    case loadInitial
    case loadMore
    case changeGrouping(GroupingOption)
    case updateSearch(String)

    // System events dispatched by Store after async work completes
    case repositoriesLoaded([Repository], nextURL: URL?)
    case detailsLoaded([String: RepositoryDetail])
    case fetchFailed(String)
}
