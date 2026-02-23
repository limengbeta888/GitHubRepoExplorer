//
//  Owner.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

struct Owner: Codable, Hashable {
    let login: String
    let avatarUrl: String?
    let type: String?           // "User" | "Organization"

    enum CodingKeys: String, CodingKey {
        case login, type
        case avatarUrl = "avatar_url"
    }
}
