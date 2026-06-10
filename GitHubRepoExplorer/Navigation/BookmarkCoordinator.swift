//
//  BookmarkCoordinator.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftUI
import Observation

enum BookmarkDestination: Hashable {
    case detail(Repository)
}

@Observable
@MainActor
final class BookmarkCoordinator: Coordinator {
    var path = NavigationPath()
    var bookmarkListViewModel: BookmarkListViewModel?
    
    let container: DependencyContainer
    
    init(container: DependencyContainer) {
        self.container = container
    }
    
    func start() {
        path = NavigationPath()
        if bookmarkListViewModel == nil {
            bookmarkListViewModel = BookmarkListViewModel(container: container, coordinator: self)
        }
    }
    
    func navigate(to destination: BookmarkDestination) {
        path.append(destination)
    }
    
    func pop() {
        path.removeLast()
    }
}
