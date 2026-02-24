//
//  RepoListView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import SwiftUI

struct RepoListView: View {
    @ObservedObject var store: RepoListStore
    @ObservedObject var bookmarkStore: BookmarkListStore
    
    private var state: RepoListState { store.state }
    
    var body: some View {
        Group {
            switch state.phase {
            case .loadingInitial:
                loadingView
            case .error(let msg) where state.repositories.isEmpty:
                errorView(msg)
            default:
                repoList
            }
        }
        .navigationTitle("GitHub Repos")
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar { toolbarContent }
        .task { store.dispatch(.loadInitial) }
        .refreshable { store.dispatch(.loadInitial) }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            
            Text("Loading repositories…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error (empty state)

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button {
                store.dispatch(.loadInitial)
            } label: {
                Text("Retry")
                    .font(.headline)
                    .padding(4)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - List

    private var repoList: some View {
        List {
            // Inline error banner when some repos are already loaded
            if case .error(let msg) = state.phase {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(msg)
                            .font(.footnote)
                    }
                }
            }

            // Background detail-enrichment indicator
            if state.phase == .fetchingDetails {
                Section {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Fetching extra details…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(state.groupedRepositories, id: \.key) { group in
                Section(header: GroupHeader(group: group.key, count: group.repos.count)) {
                    ForEach(group.repos) { repo in
                        NavigationLink(destination: RepoDetailView(store: RepoDetailStore(repo: repo))) {
                            RepoRowView(repo: repo,
                                        isBookmarked: bookmarkStore.state.isBookmarked(repo))
                        }
                        .swipeActions(edge: .trailing) {
                            bookmarkSwipeButton(for: repo)
                        }
                        .onAppear {
                            if isLastItem(repo, in: group) { store.dispatch(.loadMore) }
                        }
                    }
                }
            }

            // Pagination footer
            if state.phase == .loadingMore {
                Section {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .listRowBackground(Color.clear)
                }
            } else if !state.hasMorePages, !state.repositories.isEmpty {
                Section {
                    Text("All repositories loaded")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: state.groupedRepositories.map(\.key))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker(
                    "Group by",
                    selection: Binding(get: { state.groupingOption },
                                       set: { store.dispatch(.changeGrouping($0)) })
                ) {
                    ForEach(GroupingOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt)
                    }
                }
            } label: {
                Label("Group", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func bookmarkSwipeButton(for repo: Repository) -> some View {
        let isBookmarked = bookmarkStore.state.isBookmarked(repo)
        Button {
            bookmarkStore.dispatch(isBookmarked ? .removeBookmark(repo) : .bookmark(repo))
        } label: {
            Label(isBookmarked ? "Remove" : "Bookmark",
                  systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
        }
        .tint(isBookmarked ? .red : .accentColor)
    }

    private func isLastItem(_ repo: Repository, in group: (key: String, repos: [Repository])) -> Bool {
        repo.id == group.repos.last?.id && group.key == state.groupedRepositories.last?.key
    }
}

// MARK: - Preview

#Preview("Loaded") {
    let store = RepoListStore(service: MockGitHubService())
    store.state.repositories = Repository.allMocks
    store.state.phase = .loaded
    return NavigationStack {
        RepoListView(store: store, bookmarkStore: BookmarkListStore(persistence: MockPersistenceService()))
    }
}

#Preview("Loading") {
    let store = RepoListStore(service: MockGitHubService())
    store.state.phase = .loadingInitial
    return NavigationStack {
        RepoListView(store: store, bookmarkStore: BookmarkListStore(persistence: MockPersistenceService()))
    }
}

#Preview("Error") {
    let store = RepoListStore(service: MockGitHubService(behaviour: .rateLimited))
    store.state.phase = .error("GitHub API rate limit exceeded.")
    return NavigationStack {
        RepoListView(store: store, bookmarkStore: BookmarkListStore(persistence: MockPersistenceService()))
    }
}
