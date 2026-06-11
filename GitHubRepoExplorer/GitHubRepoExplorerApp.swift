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
                .onAppear {
                    appCoordinator.start()
                }
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    static let container = DependencyContainer()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        registerManagers()
        
        return true
    }
    
    private func registerManagers() {
        AppDelegate.container.register(githubService: GitHubService.shared,
                                       bookmarkService: BookmarkService.shared,
                                       repositoryUpdateService: RepositoryUpdateService.shared)
    }
}
