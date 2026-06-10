//
//  Owner.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
//

import Foundation

struct Owner: Hashable {
    let login: String
    let avatarUrl: String?
    let type: String?           // "User" | "Organization"
}
