//
//  ContentView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Bindable var appCoordinator: AppCoordinator

    var body: some View {
        TabView(selection: $appCoordinator.selectedTab) {
            repoTab
                .tabItem { Label("Explore", systemImage: "globe") }
                .tag(Tab.explore)
                .accessibilityIdentifier("explore_tab")

            bookmarkTab
                .tabItem { Label("Bookmarks", systemImage: "bookmark.fill") }
                .tag(Tab.bookmarks)
                .accessibilityIdentifier("bookmarks_tab")
        }
    }
    
    @ViewBuilder
    private var repoTab: some View {
        @Bindable var repoCoordinator = appCoordinator.repoCoordinator
        NavigationStack(path: $repoCoordinator.path) {
            Group {
                if let viewModel = repoCoordinator.repoListViewModel {
                    RepoListView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationDestination(for: RepoDestination.self) { destination in
                switch destination {
                case .detail(let repo):
                    RepoDetailView(viewModel: RepoDetailViewModel(
                        repository: repo,
                        container: appCoordinator.container
                    ))
                }
            }
        }
    }
    
    @ViewBuilder
    private var bookmarkTab: some View {
        @Bindable var bookmarkCoordinator = appCoordinator.bookmarkCoordinator
        NavigationStack(path: $bookmarkCoordinator.path) {
            Group {
                if let viewModel = bookmarkCoordinator.bookmarkListViewModel {
                    BookmarkListView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationDestination(for: BookmarkDestination.self) { destination in
                switch destination {
                case .detail(let repo):
                    RepoDetailView(viewModel: RepoDetailViewModel(
                        repository: repo,
                        container: appCoordinator.container
                    ))
                }
            }
        }
    }
}
