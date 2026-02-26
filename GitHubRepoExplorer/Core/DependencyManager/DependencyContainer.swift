//
//  DependencyContainer.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//


import Foundation

/// A simplet dependency manager. It is easy to use by unit tests, ui tests and real logic
final class DependencyContainer {
    static var shared = DependencyContainer()

    enum Dependency: String {
        case github
        case bookmark
        case repositoryUpdate
    }
    
    // Services
    var githubService: GitHubServiceProtocol?
    var bookmarkService: BookmarkServiceProtocol?
    var repositoryUpdateService: RepositoryUpdateServiceProtocol?

    private var dependencies: [String: Any] = [:]
    
    func register(githubService: GitHubServiceProtocol?,
                  bookmarkService: BookmarkServiceProtocol?,
                  repositoryUpdateService: RepositoryUpdateServiceProtocol?) {
        
        if let githubService {
            dependencies[Dependency.github.rawValue] = githubService
        }
        
        if let bookmarkService {
            dependencies[Dependency.bookmark.rawValue] = bookmarkService
        }
        
        if let repositoryUpdateService {
            dependencies[Dependency.repositoryUpdate.rawValue] = repositoryUpdateService
        }
    }
    
    func retrieve(_ name: Dependency) -> Any? {
        return dependencies[name.rawValue]
    }
    
    func clear() {
        dependencies.removeAll()
    }
}
