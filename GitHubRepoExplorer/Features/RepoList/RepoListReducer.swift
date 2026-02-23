//
//  RepoListReducer.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

struct RepoListReducer {
    func reduce(state: RepoListState, intent: RepoListIntent) -> RepoListState {
        var newState = state

        switch intent {
        case .onAppear:
            guard state.repos.isEmpty else { return state }
            newState.isLoading = true
            newState.errorMessage = nil

        case .loadMore:
            guard state.hasMore,
                  !state.isLoading else {
                return state
            }
            
            newState.isLoading = true
            newState.errorMessage = nil

        case .retry:
            newState.isLoading = true
            newState.errorMessage = nil
        }

        return newState
    }
}
