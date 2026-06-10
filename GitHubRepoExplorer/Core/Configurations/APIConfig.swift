//
//  APIConfig.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 10/06/2026.
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
    
    func switchTo(_ environment: AppEnvironment)
}
