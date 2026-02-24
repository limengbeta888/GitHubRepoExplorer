//
//  RepoDetailReducer.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum RepoDetailReducer {

    static func reduce(_ state: RepoDetailState, intent: RepoDetailIntent) -> RepoDetailState {
        var next = state

        switch intent {

        case .loadDetail:
            guard state.repository.stargazersCount == nil else { return state }
            next.phase = .loadingDetail

        case .toggleBookmark:
            // Flipped immediately for instant UI feedback.
            // Store persists the change as a side effect after this returns.
            next.isBookmarked.toggle()

        case .detailLoaded(let detail):
            next.repository = state.repository.merging(detail: detail)
            next.phase = .loaded

        case .bookmarkStatusLoaded(let isBookmarked):
            next.isBookmarked = isBookmarked

        case .fetchFailed(let message):
            next.phase = .error(message)
        }

        return next
    }
}
