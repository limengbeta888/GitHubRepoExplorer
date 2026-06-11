//
//  RepoListViewModel.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import Foundation
import Combine
import SwiftUI
import Observation

@Observable
@MainActor
final class RepoListViewModel {
    var repositories: [Repository] = []
    var nextPageURL: URL? = nil
    var groupingOption: GroupingOption = .ownerType
    var phase: Phase = .idle
    var collapsedGroups: Set<String> = []
    var bookmarkedIDs: Set<Int> = []
    
    enum Phase: Equatable {
        case idle
        case loadingInitial
        case loadingMore
        case fetchingDetails
        case loaded
        case error(String)
    }

    private let gitHubService: GitHubServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let repositoryUpdateService: RepositoryUpdateServiceProtocol
    private weak var coordinator: RepoCoordinator?
    
    private var fetchTask: Task<Void, Never>?
    private var detailTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init(container: DependencyContainer, coordinator: RepoCoordinator) {
        self.gitHubService = container.githubService
        self.bookmarkService = container.bookmarkService
        self.repositoryUpdateService = container.repositoryUpdateService
        self.coordinator = coordinator
        
        subscribeToServices()
    }
    
    // MARK: - Computed Properties
    
    var hasMorePages: Bool { nextPageURL != nil }
    
    var isFetching: Bool {
        phase == .loadingInitial || phase == .loadingMore
    }
    
    var hasVisibleRows: Bool {
        groupedRepositories.contains { !collapsedGroups.contains($0.key) }
    }
    
    var groupedRepositories: [(key: String, repos: [Repository])] {
        let dict = Dictionary(grouping: repositories) { repo -> String in
            switch groupingOption {
            case .ownerType: return repo.ownerTypeName
            case .forkStatus: return repo.forkStatusName
            case .language: return repo.languageGroup
            case .stargazers: return repo.stargazerBand
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
    
    // MARK: - Actions
    
    func loadInitial() {
        guard phase != .loadingInitial else { return }
        repositories = []
        nextPageURL = nil
        phase = .loadingInitial
        
        fetchTask?.cancel()
        fetchTask = Task {
            await fetchPage()
        }
    }
    
    func loadMore() {
        guard hasMorePages, !isFetching else { return }
        phase = .loadingMore
        
        fetchTask?.cancel()
        fetchTask = Task {
            await fetchPage()
        }
    }
    
    func changeGrouping(_ option: GroupingOption) {
        groupingOption = option
        if option.requiresDetail {
            triggerDetailFetchIfNeeded()
        }
    }
    
    func toggleGroup(_ key: String) {
        if collapsedGroups.contains(key) {
            collapsedGroups.remove(key)
        } else {
            collapsedGroups.insert(key)
        }
    }
    
    func toggleBookmark(_ repo: Repository, isBookmarked: Bool) {
        if isBookmarked {
            bookmarkedIDs.insert(repo.id)
            bookmarkService.addBookmark(repo)
        } else {
            bookmarkedIDs.remove(repo.id)
            bookmarkService.removeBookmark(repo)
        }
    }
    
    func showDetail(for repo: Repository) {
        coordinator?.navigate(to: .detail(repo))
    }
    
    // MARK: - Private
    
    private func fetchPage() async {
        do {
            let result: (repos: [Repository], nextURL: URL?)
            if let nextURL = nextPageURL {
                result = try await gitHubService.fetchNextRepositories(url: nextURL)
            } else {
                result = try await gitHubService.fetchRepositories()
            }
            
            repositories.append(contentsOf: result.repos)
            nextPageURL = result.nextURL
            phase = .loaded
            
            if groupingOption.requiresDetail {
                triggerDetailFetchIfNeeded()
            }
            syncBookmarks()
        } catch {
            phase = .error(error.localizedDescription)
        }
    }
    
    private func triggerDetailFetchIfNeeded() {
        let missing = repositories.filter { $0.stargazersCount == nil }
        guard !missing.isEmpty else { return }
        
        phase = .fetchingDetails
        detailTask?.cancel()
        detailTask = Task {
            let detailMap = await gitHubService.fetchDetails(for: missing)
            
            repositories = repositories.map { repo in
                guard let detail = detailMap[repo.fullName] else { return repo }
                return repo.merging(detail: detail)
            }
            phase = .loaded
            
            enrichPersistedBookmarks(with: detailMap)
        }
    }
    
    private func syncBookmarks() {
        bookmarkedIDs = bookmarkService.cachedBookmarkedIDs
    }
    
    private func enrichPersistedBookmarks(with detailMap: [String: RepositoryDetail]) {
        let saved = bookmarkService.cachedBookmarks
        saved.forEach { repo in
            guard let detail = detailMap[repo.fullName] else { return }
            bookmarkService.updateBookmark(repo.merging(detail: detail))
        }
    }
    
    private func subscribeToServices() {
        bookmarkService.bookmarksLoadedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncBookmarks()
            }
            .store(in: &cancellables)
        
        bookmarkService.bookmarkAdded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncBookmarks()
            }
            .store(in: &cancellables)

        bookmarkService.bookmarkRemoved
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncBookmarks()
            }
            .store(in: &cancellables)
        
        repositoryUpdateService.repositoryEnriched
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repo in
                guard let self, let index = self.repositories.firstIndex(where: { $0.id == repo.id }) else { return }
                self.repositories[index] = repo
            }
            .store(in: &cancellables)
    }
}
