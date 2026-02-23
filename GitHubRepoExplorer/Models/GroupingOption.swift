//
//  GroupingOption.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

enum GroupingOption: String, CaseIterable, Identifiable {
    case ownerType   = "Owner Type"
    case forkStatus  = "Fork Status"
    case language    = "Language"
    case stargazers  = "Stars"

    var id: String { rawValue }

    var requiresDetail: Bool {
        self == .language || self == .stargazers
    }
}
