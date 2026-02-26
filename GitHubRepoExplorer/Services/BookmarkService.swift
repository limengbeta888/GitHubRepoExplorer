//
//  BookmarkService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

import Foundation
import Combine

// MARK: - Protocol

protocol BookmarkServiceProtocol {
    // Subjects — stores subscribe to react to changes
    var bookmarkAdded: PassthroughSubject<Repository, Never> { get }
    var bookmarkRemoved: PassthroughSubject<Repository, Never> { get }
    var bookmarksLoadedSubject: PassthroughSubject<[Repository], Never> { get }
    var bookmarkUpdated: PassthroughSubject<Repository, Never> { get }
    var allBookmarksDeletedSubject: PassthroughSubject<Void, Never> { get }

    // In-memory cache — bookmark check without hitting persistence
    var cachedBookmarks: [Repository] { get }
    var cachedBookmarkedIDs: Set<Int> { get }

    func addBookmark(_ repo: Repository)
    func removeBookmark(_ repo: Repository)
    func updateBookmark(_ repo: Repository)
    func loadAllBookmarks()
    func deleteAllBookmarks()
}

// MARK: - Implementation

final class BookmarkService: BookmarkServiceProtocol {
    static let shared = BookmarkService()

    let bookmarkAdded = PassthroughSubject<Repository, Never>()
    let bookmarkRemoved = PassthroughSubject<Repository, Never>()
    let bookmarksLoadedSubject = PassthroughSubject<[Repository], Never>()
    let bookmarkUpdated = PassthroughSubject<Repository, Never>()
    let allBookmarksDeletedSubject = PassthroughSubject<Void, Never>()

    private(set) var cachedBookmarks: [Repository] = []
    private(set) var cachedBookmarkedIDs: Set<Int> = []

    private let persistence: PersistenceServiceProtocol
    private let repositoryUpdateService: RepositoryUpdateServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Since we need to test this service in unit tests, init methon should not be private
    init(persistence: PersistenceServiceProtocol? = nil,
         repositoryUpdateService: RepositoryUpdateServiceProtocol? = nil) {
        
        self.persistence = persistence ?? PersistenceService.shared
        self.repositoryUpdateService = repositoryUpdateService ?? RepositoryUpdateService.shared
        
        subscribeToService()
        
        loadAllBookmarks()
    }

    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - BookmarkServiceProtocol

    func addBookmark(_ repo: Repository) {
        guard !cachedBookmarkedIDs.contains(repo.id) else { return }
        
        try? persistence.add(repo)
        
        cachedBookmarks.insert(repo, at: 0)
        cachedBookmarkedIDs.insert(repo.id)
        
        bookmarkAdded.send(repo)
    }

    func removeBookmark(_ repo: Repository) {
        guard cachedBookmarkedIDs.contains(repo.id) else { return }
        
        try? persistence.remove(repo)
        
        cachedBookmarks.removeAll { $0.id == repo.id }
        cachedBookmarkedIDs.remove(repo.id)
        
        bookmarkRemoved.send(repo)
    }

    func updateBookmark(_ repo: Repository) {
        guard cachedBookmarkedIDs.contains(repo.id) else { return }
        
        try? persistence.update(repo)
        
        if let index = cachedBookmarks.firstIndex(where: { $0.id == repo.id }) {
            cachedBookmarks[index] = repo
        }
        
        bookmarkUpdated.send(repo)
    }

    func loadAllBookmarks() {
        let repos = (try? persistence.loadAllRepos()) ?? []
        cachedBookmarks = repos
        cachedBookmarkedIDs = Set(repos.map(\.id))
        
        bookmarksLoadedSubject.send(repos)
    }

    func deleteAllBookmarks() {
        try? persistence.deleteAllRepos()
        
        cachedBookmarks.removeAll()
        cachedBookmarkedIDs.removeAll()
        
        allBookmarksDeletedSubject.send()
    }
    
    // MARK: - Private
    
    private func subscribeToService() {
        repositoryUpdateService.repositoryEnriched
             .receive(on: DispatchQueue.main)
             .sink { [weak self] repo in
                 guard let self else { return }
                 // Enrich bookmark if this repo is saved
                 self.updateBookmark(repo)
             }
             .store(in: &cancellables)
    }
}
