//
//  RepoListIntent.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum RepoListIntent: Equatable {
    case onAppear
    case loadMore
    case retry
}
