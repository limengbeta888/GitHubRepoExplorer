//
//  GitHubRepoExplorerApp.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import SwiftUI

@main
struct GitHubRepoExplorerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    private var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
    }
    
    static let container = DependencyContainer()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        registerManagers()
        
        return true
    }
    
    private func registerManagers() {
        // Dependency Injection
        if isUITesting {
            AppDelegate.container.register(githubService: UITestGitHubService(),
                                           bookmarkService: MockBookmarkService(),
                                           repositoryUpdateService: MockRepositoryUpdateService())
        } else {
            AppDelegate.container.register(githubService: GitHubService.shared,
                                           bookmarkService: BookmarkService.shared,
                                           repositoryUpdateService: RepositoryUpdateService.shared)
        }
    }
}
