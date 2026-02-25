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
            next.nextPageURL = nil
            next.phase = .loadingInitial

        case .loadMore:
            guard state.hasMorePages,
                  !state.isFetching else {
                return state
            }
            next.phase = .loadingMore

        case .changeGrouping(let option):
            next.groupingOption = option

        case .toggleGroup(let key):
            if state.collapsedGroups.contains(key) {
                next.collapsedGroups.remove(key)
            } else {
                next.collapsedGroups.insert(key)
            }
            
        case .repositoriesLoaded(let repos, let nextURL):
            next.repositories.append(contentsOf: repos)
            next.nextPageURL = nextURL
            next.phase = .loaded

        case .fetchDetails:
            next.phase = .fetchingDetails
            
        case .detailsLoaded(let detailMap):
            next.repositories = state.repositories.map { repo in
                guard let detail = detailMap[repo.fullName] else {
                    return repo
                }
                return repo.merging(detail: detail)
            }
            next.phase = .loaded

        case .repositoryEnriched(let repo):
            guard let index = state.repositories.firstIndex(where: { $0.id == repo.id }) else {
                return state
            }
            next.repositories[index] = repo
            
        case .fetchFailed(let message):
            next.phase = .error(message)
        
        case .syncBookmark(let ids):
            next.bookmarkedIDs = ids
            
        case .toggleBookmark(let repo, let isBookmarked):
            if isBookmarked {
                next.bookmarkedIDs.insert(repo.id)
            } else {
                next.bookmarkedIDs.remove(repo.id)
            }
        }

        return next
    }
}
