//
//  BookmarkListView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import SwiftUI

struct BookmarkListView: View {

    @StateObject private var store: BookmarkListStore

    init(store: BookmarkListStore = .shared) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: BookmarkListState { store.state }

    var body: some View {
        Group {
            if state.filteredRepos.isEmpty {
                emptyView
            } else {
                repoList
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: Binding(get: { state.searchText },
                          set: { store.dispatch(.updateSearch($0)) }),
            prompt: "Search bookmarks…"
        )
    }

    // MARK: - Empty state

    private var emptyView: some View {
        ContentUnavailableView(
            state.searchText.isEmpty ? "No Bookmarks" : "No Results",
            systemImage: "bookmark",
            description: Text(
                state.searchText.isEmpty
                    ? "Swipe left on any repository and tap Bookmark."
                    : "No bookmarks match \"\(state.searchText)\"."
            )
        )
    }

    // MARK: - List

    private var repoList: some View {
        List {
            ForEach(state.filteredRepos) { repo in
                NavigationLink(destination: RepoDetailView(store: RepoDetailStore(repo: repo))) {
                    RepoRowView(repo: repo)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.dispatch(.removeBookmark(repo))
                    } label: {
                        Label("Remove", systemImage: "bookmark.slash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: state.filteredRepos.map(\.id))
    }
}

#Preview("Has bookmarks") {
    let store = BookmarkListStore(persistence: MockPersistenceService())
    Repository.allMocks.prefix(3).forEach { store.dispatch(.bookmark($0)) }
    return NavigationStack { BookmarkListView(store: store) }
}

#Preview("Empty") {
    NavigationStack { BookmarkListView(store: BookmarkListStore(persistence: MockPersistenceService())) }
}
