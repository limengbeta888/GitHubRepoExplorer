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
    var bookmarkAddedSubject: PassthroughSubject<Repository, Never> { get }
    var bookmarkRemovedSubject: PassthroughSubject<Repository, Never> { get }
    var bookmarksLoadedSubject: CurrentValueSubject<[Repository], Never> { get }
    var bookmarkUpdatedSubject: PassthroughSubject<Repository, Never> { get }
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

    let bookmarkAddedSubject = PassthroughSubject<Repository, Never>()
    let bookmarkRemovedSubject = PassthroughSubject<Repository, Never>()
    let bookmarksLoadedSubject = CurrentValueSubject<[Repository], Never>([])
    let bookmarkUpdatedSubject = PassthroughSubject<Repository, Never>()
    let allBookmarksDeletedSubject = PassthroughSubject<Void, Never>()

    private(set) var cachedBookmarks: [Repository] = []
    private(set) var cachedBookmarkedIDs: Set<Int> = []

    private let persistence: PersistenceServiceProtocol

    init(persistence: PersistenceServiceProtocol? = nil) {
        self.persistence = persistence ?? PersistenceService.shared
        
        loadAllBookmarks()
    }

    // MARK: - BookmarkServiceProtocol

    func addBookmark(_ repo: Repository) {
        guard !cachedBookmarkedIDs.contains(repo.id) else { return }
        
        try? persistence.add(repo)
        
        cachedBookmarks.insert(repo, at: 0)
        cachedBookmarkedIDs.insert(repo.id)
        
        bookmarkAddedSubject.send(repo)
    }

    func removeBookmark(_ repo: Repository) {
        guard cachedBookmarkedIDs.contains(repo.id) else { return }
        
        try? persistence.remove(repo)
        
        cachedBookmarks.removeAll { $0.id == repo.id }
        cachedBookmarkedIDs.remove(repo.id)
        
        bookmarkRemovedSubject.send(repo)
    }

    func updateBookmark(_ repo: Repository) {
        guard cachedBookmarkedIDs.contains(repo.id) else { return }
        
        try? persistence.update(repo)
        
        if let index = cachedBookmarks.firstIndex(where: { $0.id == repo.id }) {
            cachedBookmarks[index] = repo
        }
        
        bookmarkUpdatedSubject.send(repo)
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
}
