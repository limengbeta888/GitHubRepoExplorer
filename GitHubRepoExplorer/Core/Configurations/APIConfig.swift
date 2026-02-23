//
//  APIConfig.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

enum AppEnvironment {
    case dev
    case staging
    case prod
}

protocol APIConfigProtocol {
    var baseURL: String { get } // The current base URL
    
    var devBaseURL: String { get }
    var stagingBaseURL: String { get }
    var prodBaseURL: String { get }
    
    mutating func switchTo(_ environment: AppEnvironment)
}
