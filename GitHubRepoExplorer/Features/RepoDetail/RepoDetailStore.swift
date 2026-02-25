//
//  RepoDetailStore.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation
import Combine

@MainActor
final class RepoDetailStore: ObservableObject {
    @Published var state: RepoDetailState

    private let service: GitHubServiceProtocol
    private let persistence: PersistenceServiceProtocol

    // nil defaults resolved inside init — avoids referencing actor-isolated
    // state in a nonisolated default argument expression.
    init(
        repo: Repository,
        service: GitHubServiceProtocol? = nil,
        persistence: PersistenceServiceProtocol? = nil
    ) {
        self.state = RepoDetailState(repository: repo)
        self.service = service ?? GitHubService.shared
        self.persistence = persistence ?? PersistenceService.shared
    }

    // MARK: - Dispatch

    func dispatch(_ intent: RepoDetailIntent) {
        state = RepoDetailReducer.reduce(state, intent: intent)

        switch intent {
        case .loadDetail:
            guard state.phase == .loadingDetail else { return }
            Task {
                await fetchDetail()
            }
            
            loadBookmarkStatus()

        case .toggleBookmark:
            // State already flipped by reducer — now sync to persistence
            persistBookmarkChange()

        case .bookmarkStatusLoaded, .detailLoaded, .fetchFailed:
            break
        }
    }

    // MARK: - Private side effects

    private func fetchDetail() async {
        do {
            let detail = try await service.fetchDetail(for: state.repository)
            dispatch(.detailLoaded(detail))
        } catch {
            dispatch(.fetchFailed(error.localizedDescription))
        }
    }

    private func loadBookmarkStatus() {
        let saved = (try? persistence.loadAllRepos()) ?? []
        dispatch(.bookmarkStatusLoaded(saved.contains { $0.id == state.repository.id }))
    }

    private func persistBookmarkChange() {
        if state.isBookmarked {
            try? persistence.add(state.repository)
        } else {
            try? persistence.remove(state.repository)
        }
    }
}
