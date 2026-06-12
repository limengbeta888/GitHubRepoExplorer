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
    
    let repoCoordinator: RepoCoordinator
    let bookmarkCoordinator: BookmarkCoordinator
    let container: DependencyContainer
    let networkMonitor: NetworkMonitorProtocol

    init(container: DependencyContainer) {
        self.container = container
        self.networkMonitor = container.networkMonitor
        self.repoCoordinator = RepoCoordinator(container: container)
        self.bookmarkCoordinator = BookmarkCoordinator(container: container)
    }
    
    func start() {
        repoCoordinator.start()
        bookmarkCoordinator.start()
    }
}
