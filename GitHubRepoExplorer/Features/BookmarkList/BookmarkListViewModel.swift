//
//  BookmarkListViewModel.swift
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
final class BookmarkListViewModel {
    var bookmarkedRepos: [Repository] = []

    private let bookmarkService: BookmarkServiceProtocol
    private weak var coordinator: BookmarkCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    init(container: DependencyContainer, coordinator: BookmarkCoordinator) {
        self.bookmarkService = container.bookmarkService
        self.coordinator = coordinator
        
        subscribeToServices()
    }
    
    func loadBookmarks() {
        bookmarkService.loadAllBookmarks()
    }
    
    func removeBookmark(_ repo: Repository) {
        bookmarkService.removeBookmark(repo)
    }
    
    func showDetail(for repo: Repository) {
        coordinator?.navigate(to: .detail(repo))
    }
    
    private func subscribeToServices() {
        bookmarkService.bookmarksLoadedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repos in
                self?.bookmarkedRepos = repos
            }
            .store(in: &cancellables)
            
        bookmarkService.bookmarkAdded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadBookmarks()
            }
            .store(in: &cancellables)
            
        bookmarkService.bookmarkRemoved
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadBookmarks()
            }
            .store(in: &cancellables)
    }
}
