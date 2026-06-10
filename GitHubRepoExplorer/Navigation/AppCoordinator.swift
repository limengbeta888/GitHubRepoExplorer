//
//  AppCoordinator.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftUI
import Combine
import Observation

enum Tab: Hashable {
    case explore
    case bookmarks
}

@Observable
@MainActor
final class AppCoordinator: Coordinator {
    var selectedTab: Tab = .explore
    
    private let repoCoordinator: RepoCoordinator
    private let bookmarkCoordinator: BookmarkCoordinator
    private let container: DependencyContainer
    
    init(container: DependencyContainer) {
        self.container = container
        self.repoCoordinator = RepoCoordinator(container: container)
        self.bookmarkCoordinator = BookmarkCoordinator(container: container)
    }
    
    func start() {
        repoCoordinator.start()
        bookmarkCoordinator.start()
    }
}
