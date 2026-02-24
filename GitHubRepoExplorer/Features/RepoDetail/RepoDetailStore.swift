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

    init(
        repo: Repository,
        service: GitHubServiceProtocol? = nil,
        persistence: PersistenceServiceProtocol? = nil
    ) {
        self.state = RepoDetailState(repository: repo)
        self.service = service ?? GitHubService.shared
        self.persistence = persistence ?? UserDefaultsPersistenceService.shared
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
            
            Task {
                loadBookmarkStatus()
            }

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
        let saved: [Repository] = (try? persistence.load(forKey: .bookmarkedRepositories)) ?? []
        dispatch(.bookmarkStatusLoaded(saved.contains { $0.id == state.repository.id }))
    }

    private func persistBookmarkChange() {
        var saved: [Repository] = (try? persistence.load(forKey: .bookmarkedRepositories)) ?? []
        if state.isBookmarked {
            if !saved.contains(where: { $0.id == state.repository.id }) {
                saved.insert(state.repository, at: 0)
            }
        } else {
            saved.removeAll { $0.id == state.repository.id }
        }
        
        try? persistence.save(saved, forKey: .bookmarkedRepositories)
    }
}
