//
//  RepositoryDTO.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import Foundation

/// Full respopnse schema: https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-public-repositories

struct RepositoryDTO: Codable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let fork: Bool
    let htmlUrl: String
    let owner: OwnerDTO

    // Optional fields often missing from list responses but present in detail responses
    let stargazersCount: Int?
    let language: String?
    let forksCount: Int?
    let openIssuesCount: Int?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case fork
        case owner
        case language
        case fullName        = "full_name"
        case htmlUrl         = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount      = "forks_count"
        case openIssuesCount = "open_issues_count"
        case updatedAt       = "updated_at"
    }
}
