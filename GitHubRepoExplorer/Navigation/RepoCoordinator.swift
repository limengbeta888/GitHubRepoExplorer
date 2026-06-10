//
//  RepoCoordinator.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftUI
import Observation

enum RepoDestination: Hashable {
    case detail(Repository)
}

@Observable
@MainActor
final class RepoCoordinator: Coordinator {
    var path = NavigationPath()
    var repoListViewModel: RepoListViewModel?
    
    private let container: DependencyContainer
    
    init(container: DependencyContainer) {
        self.container = container
    }
    
    func start() {
        path = NavigationPath()
        
        if repoListViewModel == nil {
            repoListViewModel = RepoListViewModel(container: container, coordinator: self)
        }
    }
    
    func navigate(to destination: RepoDestination) {
        path.append(destination)
    }
    
    func pop() {
        path.removeLast()
    }
}
