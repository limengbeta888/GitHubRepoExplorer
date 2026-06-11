//
//  BookmarkListView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftUI

struct BookmarkListView: View {
    @Bindable var viewModel: BookmarkListViewModel

    var body: some View {
        Group {
            if viewModel.bookmarkedRepos.isEmpty {
                emptyView
            } else {
                repoList
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.automatic)
        .safeAreaInset(edge: .bottom) {
            if !viewModel.bookmarkedRepos.isEmpty {
                bottomHint
            }
        }
        .onAppear {
            viewModel.loadBookmarks()
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
            ForEach(viewModel.bookmarkedRepos) { repo in
                Button {
                    viewModel.showDetail(for: repo)
                } label: {
                    RepoRowView(repo: repo,
                                isBookmarked: .constant(true))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(repo.name)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.removeBookmark(repo)
                    } label: {
                        Label("Remove", systemImage: "bookmark.slash")
                    }
                }
                .accessibilityIdentifier("repo_row")
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: viewModel.bookmarkedRepos.map(\.id))
        .accessibilityIdentifier("bookmark_list")
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

// MARK: - Previews

#Preview("Empty - Light") {
    let container = DependencyContainer(
        githubService: MockGitHubService(),
        bookmarkService: MockBookmarkService(behaviour: .noBookmarks),
        repositoryUpdateService: MockRepositoryUpdateService()
    )
    let coordinator = BookmarkCoordinator(container: container)
    let viewModel = BookmarkListViewModel(container: container, coordinator: coordinator)
    
    return NavigationStack {
        BookmarkListView(viewModel: viewModel)
    }
    .preferredColorScheme(.light)
}

#Preview("Populated - Dark") {
    let container = DependencyContainer(
        githubService: MockGitHubService(),
        bookmarkService: MockBookmarkService(behaviour: .hasBookmarks),
        repositoryUpdateService: MockRepositoryUpdateService()
    )
    let coordinator = BookmarkCoordinator(container: container)
    let viewModel = BookmarkListViewModel(container: container, coordinator: coordinator)
    viewModel.loadBookmarks()
    
    return NavigationStack {
        BookmarkListView(viewModel: viewModel)
    }
    .preferredColorScheme(.dark)
}
