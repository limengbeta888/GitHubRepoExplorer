//
//  RepositoryDetail.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

/// Fields returned by GET /repos/{owner}/{repo} that are absent from the list endpoint.
struct RepositoryDetail: Codable, Sendable {
    let stargazersCount: Int?
    let language: String?
    let forksCount: Int?
    let openIssuesCount: Int?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case language
        case stargazersCount = "stargazers_count"
        case forksCount      = "forks_count"
        case openIssuesCount = "open_issues_count"
        case updatedAt       = "updated_at"
    }
}
