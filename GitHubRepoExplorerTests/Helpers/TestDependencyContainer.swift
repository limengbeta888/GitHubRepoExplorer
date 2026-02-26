//
//  TestDependencyContainer.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 26/02/2026.
//

//import XCTest
//import Combine
//@testable import GitHubRepoExplorer
//
//@MainActor
//final class TestDependencyContainer {
//    static func make(
//        githubService: GitHubServiceProtocol = MockGitHubService(behaviour: .success, sleepMillis: 0),
//        bookmarkService: BookmarkServiceProtocol = MockBookmarkService(behaviour: .noBookmarks),
//        repositoryUpdateService: RepositoryUpdateServiceProtocol = MockRepositoryUpdateService()
//    ) -> DependencyContainer {
//        let container = DependencyContainer()
//        container.register(
//            githubService: githubService,
//            bookmarkService: bookmarkService,
//            repositoryUpdateService: repositoryUpdateService
//        )
//        return container
//    }
//}
