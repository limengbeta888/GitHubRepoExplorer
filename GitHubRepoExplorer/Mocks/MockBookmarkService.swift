//
//  MockBookmarkService.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

import Combine

final class MockBookmarkService: BookmarkServiceProtocol {
    enum Behaviour {
        case hasBookmarks
        case noBookmarks
    }
    
    let behaviour: Behaviour
    
    let bookmarkAddedSubject = PassthroughSubject<Repository, Never>()
    let bookmarkRemovedSubject = PassthroughSubject<Repository, Never>()
    let bookmarksLoadedSubject = CurrentValueSubject<[Repository], Never>([])
    let bookmarkUpdatedSubject = PassthroughSubject<Repository, Never>()
    let allBookmarksDeletedSubject = PassthroughSubject<Void, Never>()

    private(set) var cachedBookmarks: [Repository] = []
    private(set) var cachedBookmarkedIDs: Set<Int> = []

    init(behaviour: Behaviour = .hasBookmarks) {
        self.behaviour = behaviour
    }
    
    func addBookmark(_ repo: Repository) {
        guard !cachedBookmarkedIDs.contains(repo.id) else { return }
        
        cachedBookmarks.insert(repo, at: 0)
        cachedBookmarkedIDs.insert(repo.id)
        bookmarkAddedSubject.send(repo)
    }

    func removeBookmark(_ repo: Repository) {
        cachedBookmarks.removeAll { $0.id == repo.id }
        cachedBookmarkedIDs.remove(repo.id)
        bookmarkRemovedSubject.send(repo)
    }

    func updateBookmark(_ repo: Repository) {
        guard let index = cachedBookmarks.firstIndex(where: { $0.id == repo.id }) else { return }
        
        cachedBookmarks[index] = repo
        bookmarkUpdatedSubject.send(repo)
    }

    func loadAllBookmarks() {
        switch behaviour {
        case .hasBookmarks:
            cachedBookmarks = [.mockOriginal, .mockFork, .mockOrgRepo, .mockZeroStars, .mockStars1to9]
            cachedBookmarkedIDs = Set(cachedBookmarks.map(\.id))
        case .noBookmarks:
            cachedBookmarks = []
            cachedBookmarkedIDs = []
        }
        bookmarksLoadedSubject.send(cachedBookmarks)
    }

    func deleteAllBookmarks() {
        cachedBookmarks.removeAll()
        cachedBookmarkedIDs.removeAll()
        allBookmarksDeletedSubject.send()
    }
}
