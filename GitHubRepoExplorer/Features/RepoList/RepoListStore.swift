//
//  RepoListStore.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation
import Combine

@MainActor
final class RepoListStore: ObservableObject {

    @Published var state: RepoListState = .init()

    private let service: GitHubServiceProtocol
    private let persistence: PersistenceServiceProtocol

    private var fetchTask: Task<Void, Never>?
    private var detailTask: Task<Void, Never>?

    // nil defaults resolved inside init — avoids referencing actor-isolated
    // state in a nonisolated default argument expression.
    init(
        service: GitHubServiceProtocol? = nil,
        persistence: PersistenceServiceProtocol? = nil
    ) {
        self.service     = service     ?? GitHubService.shared
        self.persistence = persistence ?? UserDefaultsPersistenceService()
    }

    // MARK: - Dispatch

    func dispatch(_ intent: RepoListIntent) {
        state = RepoListReducer.reduce(state, intent: intent)

        switch intent {

        case .loadInitial:
            fetchTask?.cancel()
            fetchTask = Task { await fetchPage() }

        case .loadMore:
            guard state.phase == .loadingMore else { return }
            fetchTask?.cancel()
            fetchTask = Task { await fetchPage() }

        case .changeGrouping(let option):
            if option.requiresDetail { triggerDetailFetchIfNeeded() }

        case .repositoriesLoaded:
            if state.groupingOption.requiresDetail { triggerDetailFetchIfNeeded() }

        case .detailsLoaded(let detailMap):
            // Enrich any persisted bookmarks that just received stars/language
            // so the Bookmarks tab shows up-to-date data without re-fetching.
            enrichPersistedBookmarks(with: detailMap)

        case .updateSearch, .fetchFailed:
            break
        }
    }

    // MARK: - Private side effects

    private func fetchPage() async {
        guard let url = state.nextPageURL else { return }
        do {
            let (repos, nextURL) = try await service.fetchRepositories(url: url)
            dispatch(.repositoriesLoaded(repos, nextURL: nextURL))
        } catch {
            dispatch(.fetchFailed(error.localizedDescription))
        }
    }

    private func triggerDetailFetchIfNeeded() {
        let missing = state.repositories.filter { $0.stargazersCount == nil }
        guard !missing.isEmpty else { return }

        var next = state
        next.phase = .fetchingDetails
        state = next

        detailTask?.cancel()
        detailTask = Task {
            let detailMap = await service.fetchDetails(for: missing)
            dispatch(.detailsLoaded(detailMap))
        }
    }

    private func enrichPersistedBookmarks(with detailMap: [String: RepositoryDetail]) {
        var saved: [Repository] = (try? persistence.load(forKey: .bookmarkedRepositories)) ?? []
        guard !saved.isEmpty else { return }
        var changed = false
        saved = saved.map { repo in
            guard let detail = detailMap[repo.fullName] else { return repo }
            changed = true
            return repo.merging(detail: detail)
        }
        if changed { try? persistence.save(saved, forKey: .bookmarkedRepositories) }
    }
}
