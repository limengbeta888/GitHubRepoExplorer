//
//  RepositoryDetailDTO.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import Foundation

struct RepositoryDetailDTO: Codable {
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

    func toDomain() -> RepositoryDetail {
        RepositoryDetail(
            stargazersCount: stargazersCount,
            language: language,
            forksCount: forksCount,
            openIssuesCount: openIssuesCount,
            updatedAt: updatedAt
        )
    }
}
