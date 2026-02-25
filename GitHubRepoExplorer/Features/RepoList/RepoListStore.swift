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
    @Published private(set) var state = RepoListState()

    private let service: GitHubServiceProtocol
    private let persistence: PersistenceServiceProtocol

    private var fetchTask: Task<Void, Never>?
    private var detailTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()
    
    // nil defaults resolved inside init — avoids referencing actor-isolated
    // state in a nonisolated default argument expression.
    init(
        service: GitHubServiceProtocol? = nil,
        persistence: PersistenceServiceProtocol? = nil
    ) {
        self.service = service ?? GitHubService.shared
        self.persistence = persistence ?? PersistenceService.shared
        
        subscribeToEvents()
    }

    // MARK: - Dispatch

    func dispatch(_ intent: RepoListIntent) {
        state = RepoListReducer.reduce(state, intent: intent)

        switch intent {
        case .loadInitial:
            guard state.phase == .loadingInitial else { return }
            fetchTask?.cancel()
            fetchTask = Task {
                await fetchPage()
            }

        case .loadMore:
            guard state.phase == .loadingMore else { return }
            fetchTask?.cancel()
            fetchTask = Task {
                await fetchPage()
            }

        case .changeGrouping(let option):
            if option.requiresDetail {
                triggerDetailFetchIfNeeded()
            }

        case .fetchDetails:
            // To fetch the information of languages and stargazers
            detailTask?.cancel()
            detailTask = Task {
                let detailMap = await service.fetchDetails(for: state.repositories.filter { $0.stargazersCount == nil })
                dispatch(.detailsLoaded(detailMap))
            }
            
        case .repositoriesLoaded:
            if state.groupingOption.requiresDetail {
                triggerDetailFetchIfNeeded()
            }

        case .detailsLoaded(let detailMap):
            // Enrich any persisted bookmarks that just received stars/language
            // so the Bookmarks tab shows up-to-date data without re-fetching.
            enrichPersistedBookmarks(with: detailMap)

        case .fetchFailed, .toggleGroup:
            break
        }
    }

    // MARK: - Subscribers
    
    private func subscribeToEvents() {
//        AppEventBus.shared.events
//            .sink { [weak self] event in
//                guard let self else { return }
//                
//                switch event {
//                case .repositoryEnriched(let repo):
//                    dispatch(.detailsLoaded([repo.fullName: repo]))
//                    
//                default:
//                    break
//                }
//            }
//            .store(in: &cancellables)
    }
    
    // MARK: - Private side effects
    
    private func fetchPage() async {
        do {
            let result = try await (state.nextPageURL == nil)
                ? service.fetchRepositories()
                : service.fetchNextRepositories(url: state.nextPageURL!)
            dispatch(.repositoriesLoaded(result.repos, nextURL: result.nextURL))
        } catch {
            dispatch(.fetchFailed(error.localizedDescription))
        }
    }

    private func triggerDetailFetchIfNeeded() {
        let missing = state.repositories.filter { $0.stargazersCount == nil }
        guard !missing.isEmpty else { return }
        
        dispatch(.fetchDetails)
    }

    private func enrichPersistedBookmarks(with detailMap: [String: RepositoryDetail]) {
        let saved = (try? persistence.loadAllRepos()) ?? []
        saved.forEach { repo in
            guard let detail = detailMap[repo.fullName] else { return }
            try? persistence.update(repo.merging(detail: detail))
        }
    }
}
