//
//  RepoListIntent.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum RepoListIntent {

    // User actions
    case loadMore
    case changeGrouping(GroupingOption)
    case toggleGroup(String)
    case toggleBookmark(Repository, isBookmarked: Bool)
    
    // System events
    case loadInitial
    case syncBookmark(Set<Int>)
    case repositoriesLoaded([Repository], nextURL: URL?)
    case fetchDetails
    case detailsLoaded([String: RepositoryDetail])
    case repositoryEnriched(Repository)
    case fetchFailed(String)
}
