//
//  BookmarkListView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import SwiftUI

struct BookmarkListView: View {
    @ObservedObject var store: BookmarkListStore

    private var state: BookmarkListState { store.state }

    var body: some View {
        Group {
            if state.bookmarkedRepos.isEmpty {
                emptyView
            } else {
                repoList
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.automatic)
        .safeAreaInset(edge: .bottom) {
            if !state.bookmarkedRepos.isEmpty {
                bottomHint
            }
        }
    }

    // MARK: - Empty state

    private var emptyView: some View {
        ContentUnavailableView(
            "No Bookmarks",
            systemImage: "bookmark",
        )
    }

    // MARK: - List

    private var repoList: some View {
        List {
            ForEach(state.bookmarkedRepos) { repo in
                NavigationLink(destination: RepoDetailView(store: RepoDetailStore(repo: repo))) {
                    RepoRowView(repo: repo,
                                isBookmarked: store.state.isBookmarked(repo))
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
        .animation(.default, value: state.bookmarkedRepos.map(\.id))
    }
    
    // MARK: - Hint
    
    private var bottomHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.point.left")
            Text("Swipe left on a repository to remove it")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Has bookmarks") {
    let store = BookmarkListStore(persistence: MockPersistenceService())
    Repository.allMocks.prefix(3).forEach { store.dispatch(.bookmark($0)) }
    return NavigationStack {
        BookmarkListView(store: store)
    }
}

#Preview("Empty") {
    NavigationStack {
        BookmarkListView(store: BookmarkListStore(persistence: MockPersistenceService()))
    }
}
