//
//  MockBookmarkService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

import Combine
import Foundation

@MainActor
final class MockBookmarkService: BookmarkServiceProtocol {
    
    enum Behaviour {
        case hasBookmarks
        case noBookmarks
    }
    
    let behaviour: Behaviour
    
    // All subjects are @MainActor-safe
    let bookmarkAdded = PassthroughSubject<Repository, Never>()
    let bookmarkRemoved = PassthroughSubject<Repository, Never>()
    let bookmarksLoadedSubject = PassthroughSubject<[Repository], Never>()
    let bookmarkUpdated = PassthroughSubject<Repository, Never>()
    let allBookmarksDeletedSubject = PassthroughSubject<Void, Never>()
    
    private(set) var cachedBookmarks: [Repository] = []
    private(set) var cachedBookmarkedIDs: Set<Int> = []
    
    private var repos: [Repository] = []
    
    init(behaviour: Behaviour = .hasBookmarks, repos: [Repository]? = nil) {
        self.behaviour = behaviour
        
        let r1 = Repository.mockOriginal
        let r2 = Repository.mockFork
        let r3 = Repository.mockOrgRepo
        let r4 = Repository.mockZeroStars
        let r5 = Repository.mockStars1to9
        self.repos = repos ?? [r1, r2, r3, r4, r5]
    }
    
    @MainActor
    func addBookmark(_ repo: Repository) {
        guard !cachedBookmarkedIDs.contains(repo.id) else { return }
        cachedBookmarks.insert(repo, at: 0)
        cachedBookmarkedIDs.insert(repo.id)
        bookmarkAdded.send(repo)
    }
    
    @MainActor
    func addBookmarkSilently(_ repo: Repository) {
        guard !cachedBookmarkedIDs.contains(repo.id) else { return }
        cachedBookmarks.insert(repo, at: 0)
        cachedBookmarkedIDs.insert(repo.id)
    }
    
    @MainActor
    func removeBookmark(_ repo: Repository) {
        cachedBookmarks.removeAll { $0.id == repo.id }
        cachedBookmarkedIDs.remove(repo.id)
        bookmarkRemoved.send(repo)
    }
    
    @MainActor
    func updateBookmark(_ repo: Repository) {
        guard let index = cachedBookmarks.firstIndex(where: { $0.id == repo.id }) else { return }
        cachedBookmarks[index] = repo
        bookmarkUpdated.send(repo)
    }
    
    @MainActor
    func loadAllBookmarks() {
        switch behaviour {
        case .hasBookmarks:
            cachedBookmarks = repos
            cachedBookmarkedIDs = Set(cachedBookmarks.map(\.id))
        case .noBookmarks:
            cachedBookmarks = []
            cachedBookmarkedIDs = []
        }
        bookmarksLoadedSubject.send(cachedBookmarks)
    }
    
    @MainActor
    func deleteAllBookmarks() {
        cachedBookmarks.removeAll()
        cachedBookmarkedIDs.removeAll()
        allBookmarksDeletedSubject.send()
    }
}
