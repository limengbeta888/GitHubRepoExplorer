//
//  ContentView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var repoListStore = RepoListStore()
    @StateObject private var bookmarkListStore = BookmarkListStore()
    
    var body: some View {
        TabView {
            NavigationStack {
                RepoListView(store: repoListStore)
            }
            .tabItem { Label("Explore", systemImage: "globe") }

            NavigationStack {
                BookmarkListView(store: bookmarkListStore)
            }
            .tabItem { Label("Bookmarks", systemImage: "bookmark.fill") }
        }
    }
}
