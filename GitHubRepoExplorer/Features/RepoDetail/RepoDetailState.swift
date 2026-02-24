//
//  RepoDetailState.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

struct RepoDetailState: Equatable {
    var repository: Repository
    var isBookmarked: Bool = false
    var phase: Phase = .idle

    enum Phase: Equatable {
        case idle
        case loadingDetail
        case loaded
        case error(String)
    }

    init(repository: Repository) {
        self.repository = repository
        
        // Skip fetching if detail fields already present (enriched by list)
        self.phase = repository.stargazersCount != nil ? .loaded : .idle
    }
}
