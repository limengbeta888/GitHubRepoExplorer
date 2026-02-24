//
//  RepoDetailIntent.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum RepoDetailIntent {

    // User actions
    case loadDetail
    case toggleBookmark

    // System events
    case detailLoaded(RepositoryDetail)
    case bookmarkStatusLoaded(Bool)
    case fetchFailed(String)
}
