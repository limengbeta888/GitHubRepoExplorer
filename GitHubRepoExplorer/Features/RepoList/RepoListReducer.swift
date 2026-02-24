//
//  RepoListReducer.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum RepoListReducer {

    static func reduce(_ state: RepoListState, intent: RepoListIntent) -> RepoListState {
        var next = state

        switch intent {

        case .loadInitial:
            next.repositories = []
            next.nextPageURL = URL(string: "https://api.github.com/repositories")
            next.phase = .loadingInitial

        case .loadMore:
            guard state.hasMorePages, !state.isFetching else { return state }
            next.phase = .loadingMore

        case .changeGrouping(let option):
            next.groupingOption = option

        case .updateSearch(let text):
            next.searchText = text

        case .repositoriesLoaded(let repos, let nextURL):
            next.repositories.append(contentsOf: repos)
            next.nextPageURL = nextURL
            next.phase = .loaded

        case .detailsLoaded(let detailMap):
            next.repositories = state.repositories.map { repo in
                guard let detail = detailMap[repo.fullName] else { return repo }
                return repo.merging(detail: detail)
            }
            next.phase = .loaded

        case .fetchFailed(let message):
            next.phase = .error(message)
        }

        return next
    }
}
