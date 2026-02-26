//
//  RepoListView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import SwiftUI

struct RepoListView: View {
    @ObservedObject var store: RepoListStore
    
    private var state: RepoListState {
        store.state
    }
    
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
        .toolbar {
            toolbarContent
        }
        .task {
            guard state.phase == .idle else { return }
            store.dispatch(.loadInitial)
        }
        .refreshable {
            guard state.repositories.isEmpty else { return }
            store.dispatch(.loadInitial)
        }
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
            // Inline error banner when some repos are already loaded (e.g. show api rate limit error)
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
                Section {
                    if !state.collapsedGroups.contains(group.key) {
                        ForEach(group.repos) { repo in
                            NavigationLink(destination: RepoDetailView(store: RepoDetailStore(repo: repo))) {
                                RepoRowView(repo: repo,
                                            isBookmarked: Binding(
                                                get: {
                                                    state.bookmarkedIDs.contains(repo.id)
                                                },
                                                set: { isBookmarked in
                                                    store.dispatch(.toggleBookmark(repo, isBookmarked: isBookmarked))
                                                }
                                            ))
                            }
                            .swipeActions(edge: .trailing) {
                                bookmarkSwipeButton(for: repo)
                            }
                        }
                    }
                } header: {
                    Button {
                        store.dispatch(.toggleGroup(group.key))
                    } label: {
                        HStack {
                            Text(group.key).font(.headline)
                            
                            Spacer()
                            
                            Text("\(group.repos.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                            
                            Image(systemName: state.collapsedGroups.contains(group.key)
                                  ? "chevron.right" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Always rendered — completely independent of section collapse state
            paginationFooter
        }
        .listStyle(.insetGrouped)
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
                        Text(opt.rawValue)
                            .tag(opt)
                    }
                }
            } label: {
                Label("Group", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var paginationFooter: some View {
        Section {
            switch state.phase {
            case .loadingMore:
                HStack {
                    Spacer();
                    ProgressView();
                    Spacer()
                }
                .listRowBackground(Color.clear)

            case .loaded where state.hasMorePages && state.hasVisibleRows:
                // Invisible sentinel — triggers load when it scrolls into view
                Color.clear
                    .frame(height: 1)
                    .listRowBackground(Color.clear)
                    .onAppear {
                        store.dispatch(.loadMore)
                    }

            case .loaded where !state.hasMorePages && !state.repositories.isEmpty:
                Text("All repositories loaded")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)

            default:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func bookmarkSwipeButton(for repo: Repository) -> some View {
        let isBookmarked = state.bookmarkedIDs.contains(repo.id)
        Button {
            store.dispatch(.toggleBookmark(repo, isBookmarked: !isBookmarked))
        } label: {
            Label(isBookmarked ? "Remove" : "Bookmark",
                  systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
        }
        .tint(isBookmarked ? .red : .accentColor)
    }
}

// MARK: - Preview

#Preview("Loaded") {
    let store = RepoListStore(gitHubService: MockGitHubService())
    return NavigationStack {
        RepoListView(store: store)
    }
}

#Preview("Loading") {
    let gitHubService = MockGitHubService(behaviour: .success, sleepMillis: 10000)
    let store = RepoListStore(gitHubService: gitHubService)
    return NavigationStack {
        RepoListView(store: store)
    }
}

#Preview("Error") {
    let store = RepoListStore(gitHubService: MockGitHubService(behaviour: .networkError))
    return NavigationStack {
        RepoListView(store: store)
    }
}
