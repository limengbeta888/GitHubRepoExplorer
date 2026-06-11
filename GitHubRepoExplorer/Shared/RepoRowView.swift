//
//  RepoRowView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import SwiftUI

struct RepoRowView: View {
    let repo: Repository
    let detailVisible: Bool
    @Binding var isBookmarked: Bool

    init(repo: Repository, isBookmarked: Binding<Bool>, detailVisible: Bool = true) {
        self.repo = repo
        self._isBookmarked = isBookmarked
        self.detailVisible = detailVisible
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(urlString: repo.owner.avatarUrl, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(repo.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                
                Text(repo.owner.login)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    if detailVisible {
                        if let lang = repo.language {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                Text(lang)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        
                        if let stars = repo.stargazersCount {
                            HStack(spacing: 4) {
                                Image(systemName: "star")
                                Text("\(stars)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }

                    if repo.fork {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.branch")
                            Text("Fork")
                        }
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("repo_row")
        .accessibilityLabel(repo.name)
    }
}

// MARK: - Previews

#Preview("Standard - Light") {
    RepoRowView(
        repo: Repository.mockFork,
        isBookmarked: .constant(false)
    )
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Bookmarked Fork - Dark") {
    RepoRowView(
        repo: Repository.mockFork,
        isBookmarked: .constant(true)
    )
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Long Description") {
    RepoRowView(
        repo: Repository.mockOrgRepo,
        isBookmarked: .constant(false)
    )
    .padding()
    .preferredColorScheme(.light)
}
