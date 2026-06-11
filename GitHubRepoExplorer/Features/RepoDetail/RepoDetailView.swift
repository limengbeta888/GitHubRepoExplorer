//
//  RepoDetailView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import SwiftUI

struct RepoDetailView: View {
    @Bindable var viewModel: RepoDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                statsGrid
                openInBrowserButton
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.repository.name)
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            toolbarContent
        }
        .onAppear {
            viewModel.loadDetail()
        }
        .safeAreaInset(edge: .bottom) {
            if case .error(let msg) = viewModel.phase {
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
            AvatarView(urlString: viewModel.repository.owner.avatarUrl, size: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.repository.fullName)
                    .font(.title3.bold())
                
                if let desc = viewModel.repository.description, !desc.isEmpty {
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
                             value: viewModel.repository.stargazersCount.map { "\($0)" } ?? "—",
                             icon: "star.fill",
                             color: .yellow)
                
                RepoInfoCard(title: "Forks",
                             value: viewModel.repository.forksCount.map { "\($0)" } ?? "—",
                             icon: "arrow.branch",
                             color: .blue)
                
                RepoInfoCard(title: "Open Issues",
                             value: viewModel.repository.openIssuesCount.map { "\($0)" } ?? "—",
                             icon: "exclamationmark.circle",
                             color: .red)
                
                RepoInfoCard(title: "Language",
                             value: viewModel.repository.language ?? "Unknown",
                             icon: "chevron.left.forwardslash.chevron.right",
                             color: .green)
                
                RepoInfoCard(title: "Owner Type",
                             value: viewModel.repository.owner.type ?? "Unknown",
                             icon: "person.circle",
                             color: .purple)
                
                RepoInfoCard(title: "Fork",
                             value: viewModel.repository.fork ? "Yes" : "No",
                             icon: "arrow.triangle.branch",
                             color: .orange)
            }
            .padding(.horizontal)

            if viewModel.phase == .loadingDetail {
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
        if let url = URL(string: viewModel.repository.htmlUrl) {
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
                viewModel.toggleBookmark()
            } label: {
                Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
            }
            .tint(viewModel.isBookmarked ? .yellow : .gray)
            .accessibilityIdentifier(
                viewModel.isBookmarked ? "bookmark_fill_button" : "bookmark_button")
        }
    }
}

// MARK: - Previews

#Preview("Loaded - Light") {
    let container = DependencyContainer(
        githubService: MockGitHubService(),
        bookmarkService: MockBookmarkService(),
        repositoryUpdateService: MockRepositoryUpdateService()
    )
    let repo = Repository.mockOrgRepo
    let viewModel = RepoDetailViewModel(repository: repo, container: container)
    
    return NavigationStack {
        RepoDetailView(viewModel: viewModel)
    }
    .preferredColorScheme(.light)
}

#Preview("Loading - Dark") {
    let container = DependencyContainer(
        githubService: MockGitHubService(),
        bookmarkService: MockBookmarkService(),
        repositoryUpdateService: MockRepositoryUpdateService()
    )
    // Create a repo without details to trigger loading state
    let repo = Repository.mockOriginal
    let viewModel = RepoDetailViewModel(repository: repo, container: container)
    viewModel.phase = .loadingDetail
    
    return NavigationStack {
        RepoDetailView(viewModel: viewModel)
    }
    .preferredColorScheme(.dark)
}

#Preview("Error") {
    let container = DependencyContainer(
        githubService: MockGitHubService(),
        bookmarkService: MockBookmarkService(),
        repositoryUpdateService: MockRepositoryUpdateService()
    )
    let repo = Repository.mockOriginal
    let viewModel = RepoDetailViewModel(repository: repo, container: container)
    viewModel.phase = .error("Failed to load details. Please check your internet connection.")
    
    return NavigationStack {
        RepoDetailView(viewModel: viewModel)
    }
}
