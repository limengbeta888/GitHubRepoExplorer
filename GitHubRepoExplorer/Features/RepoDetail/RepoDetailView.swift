//
//  RepoDetailView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import SwiftUI

struct RepoDetailView: View {

    @StateObject private var store: RepoDetailStore

    init(store: RepoDetailStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: RepoDetailState { store.state }
    private var repo: Repository       { state.repository }

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { store.dispatch(.loadDetail) }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            AvatarView(urlString: repo.owner.avatarUrl, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(repo.fullName).font(.title3.bold())
                if let desc = repo.description, !desc.isEmpty {
                    Text(desc).font(.body).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        ZStack {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Stars",
                         value: repo.stargazersCount.map { "\($0)" } ?? "—",
                         icon: "star.fill", color: .yellow)
                StatCard(title: "Forks",
                         value: repo.forksCount.map { "\($0)" } ?? "—",
                         icon: "arrow.branch", color: .blue)
                StatCard(title: "Open Issues",
                         value: repo.openIssuesCount.map { "\($0)" } ?? "—",
                         icon: "exclamationmark.circle", color: .red)
                StatCard(title: "Language",
                         value: repo.language ?? "Unknown",
                         icon: "chevron.left.forwardslash.chevron.right", color: .green)
                StatCard(title: "Owner Type",
                         value: repo.owner.type ?? "Unknown",
                         icon: "person.circle", color: .purple)
                StatCard(title: "Fork",
                         value: repo.fork ? "Yes" : "No",
                         icon: "arrow.triangle.branch", color: .orange)
            }
            .padding(.horizontal)

            if state.phase == .loadingDetail {
                ProgressView()
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if case .error(let msg) = state.phase {
                Text(msg)
                    .font(.footnote).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding()
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
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { store.dispatch(.toggleBookmark) } label: {
                Image(systemName: state.isBookmarked ? "bookmark.fill" : "bookmark")
            }
        }
    }
}

// MARK: - StatCard

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Text(value).font(.title3.bold()).lineLimit(1).minimumScaleFactor(0.7)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Detail loaded") {
    NavigationStack { RepoDetailView(store: RepoDetailStore(repo: .mockOrgRepo)) }
}
#Preview("Pending fetch") {
    NavigationStack { RepoDetailView(store: RepoDetailStore(repo: .mockOriginal)) }
}
