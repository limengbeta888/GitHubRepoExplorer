//
//  RepoRowView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

import SwiftUI

struct RepoRowView: View {
    let repo: Repository
    @Binding var isBookmarked: Bool

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
                            .font(.caption).foregroundStyle(.tint)
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
                    if let lang = repo.language {
                        Label(lang, systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let stars = repo.stargazersCount {
                        Label("\(stars)", systemImage: "star")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if repo.fork {
                        Label("Fork", systemImage: "arrow.branch")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Fork") {
    return RepoRowView(repo: Repository.mockFork, isBookmarked: .constant(true))
}

#Preview("Original") {
    return RepoRowView(repo: Repository.mockOriginal, isBookmarked: .constant(true))
}
