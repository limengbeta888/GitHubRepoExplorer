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
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: Binding(get: { state.searchText },
                          set: { store.dispatch(.updateSearch($0)) }),
            prompt: "Search repos, owners…"
        )
        .toolbar { toolbarContent }
        .task { store.dispatch(.loadInitial) }
        .refreshable { store.dispatch(.loadInitial) }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.4)
            Text("Loading repositories…").foregroundStyle(.secondary)
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
            Button("Retry") { store.dispatch(.loadInitial) }
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
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(msg).font(.footnote)
                    }
                }
            }

            // Background detail-enrichment indicator
            if state.phase == .fetchingDetails {
                Section {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.8)
                        Text("Fetching extra details…").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(state.groupedRepositories, id: \.key) { group in
                Section(header: groupHeader(group.key, count: group.repos.count)) {
                    ForEach(group.repos) { repo in
                        NavigationLink(destination: RepoDetailView(store: RepoDetailStore(repo: repo))) {
                            RepoRowView(repo: repo)
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
                        .font(.footnote).foregroundStyle(.secondary)
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

    private func groupHeader(_ key: String, count: Int) -> some View {
        HStack {
            Text(key).font(.headline)
            Spacer()
            Text("\(count)")
                .font(.caption).padding(.horizontal, 8).padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
        }
    }

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

// MARK: - RepoRowView

struct RepoRowView: View {

    let repo: Repository
    @StateObject private var bookmarkStore = BookmarkListStore.shared

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(urlString: repo.owner.avatarUrl, size: 40)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(repo.name).font(.headline).lineLimit(1)
                    if bookmarkStore.state.isBookmarked(repo) {
                        Image(systemName: "bookmark.fill")
                            .font(.caption).foregroundStyle(.tint)
                    }
                }
                Text(repo.owner.login).font(.caption).foregroundStyle(.secondary)
                if let desc = repo.description, !desc.isEmpty {
                    Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                HStack(spacing: 12) {
                    if let lang = repo.language {
                        Label(lang, systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    if let stars = repo.stargazersCount {
                        Label("\(stars)", systemImage: "star")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    if repo.fork {
                        Label("Fork", systemImage: "arrow.branch")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
