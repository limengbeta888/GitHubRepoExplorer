//
//  RepoListView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftUI

struct RepoListView: View {
    @Bindable var viewModel: RepoListViewModel
    
    var body: some View {
        Group {
            switch viewModel.phase {
            case .loadingInitial:
                loadingView
            case .error(let msg) where viewModel.repositories.isEmpty:
                errorView(msg)
            default:
                repoList
            }
        }
        .animation(.default, value: viewModel.phase)
        .navigationTitle("GitHub Repos")
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            toolbarContent
        }
        .onAppear {
            guard viewModel.phase == .idle else { return }
            viewModel.loadInitial()
        }
        .refreshable {
            guard viewModel.repositories.isEmpty else { return }
            viewModel.loadInitial()
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
                viewModel.loadInitial()
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
            if case .error(let msg) = viewModel.phase {
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
            if viewModel.phase == .fetchingDetails {
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
            
            ForEach(viewModel.groupedRepositories, id: \.key) { group in
                Section {
                    if !viewModel.collapsedGroups.contains(group.key) {
                        ForEach(group.repos) { repo in
                            Button {
                                viewModel.showDetail(for: repo)
                            } label: {
                                RepoRowView(repo: repo,
                                            isBookmarked: Binding(
                                                get: { viewModel.bookmarkedIDs.contains(repo.id) },
                                                set: { viewModel.toggleBookmark(repo, isBookmarked: $0) }
                                            ))
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                bookmarkSwipeButton(for: repo)
                            }
                            .accessibilityLabel(repo.name)
                        }
                    }
                } header: {
                    Button {
                        viewModel.toggleGroup(group.key)
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
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(viewModel.collapsedGroups.contains(group.key) ? 0 : 90))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .accessibilityIdentifier("group_header")
                .accessibilityLabel("\(group.key), \(group.repos.count)")
            }
            
            paginationFooter
        }
        .listStyle(.insetGrouped)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.collapsedGroups)
        .accessibilityIdentifier("repo_list")
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker(
                    "Group by",
                    selection: $viewModel.groupingOption
                ) {
                    ForEach(GroupingOption.allCases) { opt in
                        Text(opt.rawValue)
                            .tag(opt)
                    }
                }
                .onChange(of: viewModel.groupingOption) { oldValue, newValue in
                    viewModel.changeGrouping(newValue)
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
            switch viewModel.phase {
            case .loadingMore:
                HStack {
                    Spacer();
                    ProgressView();
                    Spacer()
                }
                .listRowBackground(Color.clear)

            case .loaded where viewModel.hasMorePages && viewModel.hasVisibleRows:
                Color.clear
                    .frame(height: 1)
                    .listRowBackground(Color.clear)
                    .onAppear {
                        viewModel.loadMore()
                    }

            case .loaded where !viewModel.hasMorePages && !viewModel.repositories.isEmpty:
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
        let isBookmarked = viewModel.bookmarkedIDs.contains(repo.id)
        Button {
            viewModel.toggleBookmark(repo, isBookmarked: !isBookmarked)
        } label: {
            Label(isBookmarked ? "Remove" : "Bookmark",
                  systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
        }
        .tint(isBookmarked ? .red : .accentColor)
    }
}

// MARK: - Previews

#Preview("Loaded - Light") {
    let container = DependencyContainer(
        githubService: MockGitHubService(),
        bookmarkService: MockBookmarkService(),
        repositoryUpdateService: MockRepositoryUpdateService()
    )
    let coordinator = RepoCoordinator(container: container)
    let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
    viewModel.repositories = Repository.allMocks
    viewModel.phase = .loaded
    
    return NavigationStack {
        RepoListView(viewModel: viewModel)
    }
    .preferredColorScheme(.light)
}

#Preview("Loading - Dark") {
    let container = DependencyContainer(
        githubService: MockGitHubService(),
        bookmarkService: MockBookmarkService(),
        repositoryUpdateService: MockRepositoryUpdateService()
    )
    let coordinator = RepoCoordinator(container: container)
    let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
    viewModel.phase = .loadingInitial
    
    return NavigationStack {
        RepoListView(viewModel: viewModel)
    }
    .preferredColorScheme(.dark)
}

#Preview("Error") {
    let container = DependencyContainer(
        githubService: MockGitHubService(),
        bookmarkService: MockBookmarkService(),
        repositoryUpdateService: MockRepositoryUpdateService()
    )
    let coordinator = RepoCoordinator(container: container)
    let viewModel = RepoListViewModel(container: container, coordinator: coordinator)
    viewModel.phase = .error("API Rate Limit Reached")
    
    return NavigationStack {
        RepoListView(viewModel: viewModel)
    }
}
