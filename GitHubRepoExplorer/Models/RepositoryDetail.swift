//
//  RepositoryDetail.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import Foundation

/// Fields returned by GET /repos/{owner}/{repo} that are absent from the list endpoint.
struct RepositoryDetail: Sendable {
    let stargazersCount: Int?
    let language: String?
    let forksCount: Int?
    let openIssuesCount: Int?
    let updatedAt: String?
}
