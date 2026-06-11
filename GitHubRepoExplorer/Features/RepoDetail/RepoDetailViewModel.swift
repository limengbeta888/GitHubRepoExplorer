//
//  RepoDetailViewModel.swift
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
final class RepoDetailViewModel {
    var repository: Repository
    var isBookmarked: Bool = false
    var phase: Phase = .idle

    enum Phase: Equatable {
        case idle
        case loadingDetail
        case loaded
        case error(String)
    }

    private let githubService: GitHubServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let repositoryUpdateService: RepositoryUpdateServiceProtocol
    
    private var detailTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: Repository, container: DependencyContainer) {
        self.repository = repository
        self.githubService = container.githubService
        self.bookmarkService = container.bookmarkService
        self.repositoryUpdateService = container.repositoryUpdateService
        
        // Initial state
        self.phase = repository.stargazersCount != nil ? .loaded : .idle
        self.isBookmarked = bookmarkService.cachedBookmarkedIDs.contains(repository.id)
        
        subscribeToServices()
    }
    
    func loadDetail() {
        guard repository.stargazersCount == nil, phase != .loadingDetail else { return }
        phase = .loadingDetail
        
        detailTask?.cancel()
        detailTask = Task {
            do {
                let detail = try await githubService.fetchDetail(for: repository)
                repository = repository.merging(detail: detail)
                phase = .loaded
                repositoryUpdateService.publishEnrichment(repository)
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }
    
    func toggleBookmark() {
        isBookmarked.toggle()
        if isBookmarked {
            bookmarkService.addBookmark(repository)
        } else {
            bookmarkService.removeBookmark(repository)
        }
    }
    
    private func subscribeToServices() {
        bookmarkService.bookmarkAdded
            .filter { [weak self] in $0.id == self?.repository.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isBookmarked = true
            }
            .store(in: &cancellables)

        bookmarkService.bookmarkRemoved
            .filter { [weak self] in $0.id == self?.repository.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isBookmarked = false
            }
            .store(in: &cancellables)
    }
}
