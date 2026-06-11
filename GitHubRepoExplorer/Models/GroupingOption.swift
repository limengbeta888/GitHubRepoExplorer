//
//  GroupingOption.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import Foundation

enum GroupingOption: String, CaseIterable, Identifiable {
    case ownerType  = "Owner Type"
    case forkStatus = "Fork Status"
    case language   = "Language"
    case stargazers = "Stars"

    var id: String { rawValue }

    /// Language and Stars groupings require fetching /repos/{owner}/{repo}.
    var requiresDetail: Bool {
        self == .language || self == .stargazers
    }
}
