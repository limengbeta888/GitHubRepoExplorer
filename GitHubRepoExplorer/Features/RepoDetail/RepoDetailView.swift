//
//  RepoDetailView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import SwiftUI

struct RepoDetailView: View {
    @ObservedObject var store: RepoDetailStore

    private var state: RepoDetailState {
        store.state
    }
    
    private var repo: Repository {
        state.repository
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                statsGrid
                openInBrowserButton
            }
            .padding(.vertical)
        }
        .navigationTitle(repo.name)
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            toolbarContent
        }
        .task {
            store.dispatch(.loadDetail)
        }
        .safeAreaInset(edge: .bottom) {
            if case .error(let msg) = state.phase {
                HStack {
                    Spacer()
                    
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Spacer()
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            AvatarView(urlString: repo.owner.avatarUrl, size: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(repo.fullName)
                    .font(.title3.bold())
                
                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        ZStack {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                RepoInfoCard(title: "Stars",
                             value: repo.stargazersCount.map { "\($0)" } ?? "—",
                             icon: "star.fill",
                             color: .yellow)
                
                RepoInfoCard(title: "Forks",
                             value: repo.forksCount.map { "\($0)" } ?? "—",
                             icon: "arrow.branch",
                             color: .blue)
                
                RepoInfoCard(title: "Open Issues",
                             value: repo.openIssuesCount.map { "\($0)" } ?? "—",
                             icon: "exclamationmark.circle",
                             color: .red)
                
                RepoInfoCard(title: "Language",
                             value: repo.language ?? "Unknown",
                             icon: "chevron.left.forwardslash.chevron.right",
                             color: .green)
                
                RepoInfoCard(title: "Owner Type",
                             value: repo.owner.type ?? "Unknown",
                             icon: "person.circle",
                             color: .purple)
                
                RepoInfoCard(title: "Fork",
                             value: repo.fork ? "Yes" : "No",
                             icon: "arrow.triangle.branch",
                             color: .orange)
            }
            .padding(.horizontal)

            if state.phase == .loadingDetail {
                ProgressView()
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Open in browser

    @ViewBuilder
    private var openInBrowserButton: some View {
        if let url = URL(string: repo.htmlUrl) {
            Link(destination: url) {
                Label("Open on GitHub", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .accessibilityLabel("Open on GitHub")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.dispatch(.toggleBookmark)
            } label: {
                Image(systemName: state.isBookmarked ? "bookmark.fill" : "bookmark")
            }
            .tint(state.isBookmarked ? .yellow : .gray)
            .accessibilityIdentifier(
                state.isBookmarked ? "bookmark_fill_button" : "bookmark_button")
        }
    }
}

// MARK: - Preview

#Preview("Detail loaded") {
    let container = DependencyContainer()
    container.register(githubService: MockGitHubService(),
                       bookmarkService: MockBookmarkService(),
                       repositoryUpdateService: MockRepositoryUpdateService())
    let store = RepoDetailStore(repo: .mockOrgRepo,
                                container: container)
    return NavigationStack {
        RepoDetailView(store: store)
    }
}

#Preview("Pending fetch") {
    let container = DependencyContainer()
    container.register(githubService: MockGitHubService(behaviour: .success, sleepMillis: 10000),
                       bookmarkService: MockBookmarkService(),
                       repositoryUpdateService: MockRepositoryUpdateService())
    
    let store = RepoDetailStore(repo: .mockOrgRepo,
                                container: container)
    return NavigationStack {
        RepoDetailView(store: store)
    }
}

#Preview("Error") {
    let container = DependencyContainer()
    container.register(githubService: MockGitHubService(behaviour: .networkError, sleepMillis: 10000),
                       bookmarkService: MockBookmarkService(),
                       repositoryUpdateService: MockRepositoryUpdateService())
    
    let store = RepoDetailStore(repo: .mockOrgRepo,
                                container: container)
    return NavigationStack {
        RepoDetailView(store: store)
    }
}
