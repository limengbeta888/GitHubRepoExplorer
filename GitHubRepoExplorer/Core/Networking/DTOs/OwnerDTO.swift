//
//  OwnerDTO.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

/// Full respopnse schema: https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-public-repositories

struct OwnerDTO: Codable {
    let login: String
    let avatarUrl: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case login
        case type
        case avatarUrl = "avatar_url"
    }
}
