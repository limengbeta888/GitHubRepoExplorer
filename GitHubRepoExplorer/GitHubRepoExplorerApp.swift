//
//  GitHubRepoExplorerApp.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftUI
import SwiftData

// MARK: - GitHubRepoExplorerApp

@main
struct GitHubRepoExplorerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var appCoordinator = AppCoordinator(container: AppDelegate.container)
    
    var body: some Scene {
        WindowGroup {
            ContentView(appCoordinator: appCoordinator)
                .environment(\.dependencyContainer, AppDelegate.container)
                .onAppear {
                    appCoordinator.start()
                }
        }
    }
}

// MARK: - AppDelegate

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
            // Note: These would need to be MainActor-isolated or handled carefully
            AppDelegate.container.register(githubService: UITestGitHubService(),
                                           bookmarkService: MockBookmarkService(behaviour: .noBookmarks),
                                           repositoryUpdateService: MockRepositoryUpdateService())
        } else {
            AppDelegate.container.register(githubService: GitHubService.shared,
                                           bookmarkService: BookmarkService.shared,
                                           repositoryUpdateService: RepositoryUpdateService.shared)
        }
    }
}
