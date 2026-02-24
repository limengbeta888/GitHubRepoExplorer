//
//  RepoListState.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

struct RepoListState: Equatable {
    var repositories: [Repository] = []
    var nextPageURL: URL?
    var groupingOption: GroupingOption = .ownerType
    var phase: Phase = .idle

    // MARK: - Phase

    enum Phase: Equatable {
        case idle
        case loadingInitial
        case loadingMore
        case fetchingDetails
        case loaded
        case error(String)
    }

    // MARK: - Computed

    var hasMorePages: Bool { nextPageURL != nil }

    var isFetching: Bool {
        phase == .loadingInitial || phase == .loadingMore
    }

    var groupedRepositories: [(key: String, repos: [Repository])] {
        let dict = Dictionary(grouping: repositories) { repo -> String in
            switch groupingOption {
            case .ownerType:
                return repo.ownerTypeName
                
            case .forkStatus:
                return repo.forkStatusName
                
            case .language:
                return repo.languageGroup
                
            case .stargazers:
                return repo.stargazerBand
            }
        }
        
        return dict
            .map { (key: $0.key, repos: $0.value) }
            .sorted { lhs, rhs in
                if groupingOption == .stargazers {
                    return (lhs.repos.first?.stargazerBandOrder ?? -1) >
                           (rhs.repos.first?.stargazerBandOrder ?? -1)
                }
                return lhs.key < rhs.key
            }
    }
}
