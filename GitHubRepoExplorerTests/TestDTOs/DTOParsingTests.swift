//
//  DTOParsingTests.swift
//  GitHubRepoExplorerTests
//

import Testing
import Foundation
@testable import GitHubRepoExplorer

@MainActor
@Suite("DTO Parsing Tests", .serialized)
struct DTOParsingTests {
    
    private let decoder = JSONDecoder()

    @Test("Parse RepositoryDTO from real list JSON")
    func parseRepositoryList() throws {
        let json = """
        [
          {
            "id": 1296269,
            "name": "Hello-World",
            "full_name": "octocat/Hello-World",
            "owner": {
              "login": "octocat",
              "id": 1,
              "avatar_url": "https://github.com/images/error/octocat_happy.gif",
              "type": "User"
            },
            "private": false,
            "html_url": "https://github.com/octocat/Hello-World",
            "description": "This your first repo!",
            "fork": false,
            "url": "https://api.github.com/repos/octocat/Hello-World"
          }
        ]
        """
        let data = json.data(using: .utf8)!
        let repos = try decoder.decode([RepositoryDTO].self, from: data)
        
        #expect(repos.count == 1)
        let repo = repos[0]
        #expect(repo.id == 1296269)
        #expect(repo.name == "Hello-World")
        #expect(repo.fullName == "octocat/Hello-World")
        #expect(repo.owner.login == "octocat")
        #expect(repo.owner.type == "User")
        #expect(repo.owner.avatarUrl == "https://github.com/images/error/octocat_happy.gif")
        #expect(repo.description == "This your first repo!")
        #expect(repo.fork == false)
    }

    @Test("Parse RepositoryDetailDTO from real detail JSON")
    func parseRepositoryDetail() throws {
        let json = """
        {
          "id": 1296269,
          "name": "Hello-World",
          "stargazers_count": 80,
          "forks_count": 9,
          "open_issues_count": 0,
          "language": "Swift",
          "updated_at": "2011-01-26T19:14:43Z"
        }
        """
        let data = json.data(using: .utf8)!
        let detail = try decoder.decode(RepositoryDetailDTO.self, from: data)
        
        #expect(detail.stargazersCount == 80)
        #expect(detail.forksCount == 9)
        #expect(detail.openIssuesCount == 0)
        #expect(detail.language == "Swift")
        #expect(detail.updatedAt == "2011-01-26T19:14:43Z")
    }

    @Test("Parse RepositoryDTO with missing optional fields")
    func parseRepositoryWithMissingOptionals() throws {
        let json = """
        [
          {
            "id": 123,
            "name": "minimal",
            "full_name": "owner/minimal",
            "owner": { "login": "owner" },
            "fork": true,
            "html_url": "url"
          }
        ]
        """
        let data = json.data(using: .utf8)!
        let repos = try decoder.decode([RepositoryDTO].self, from: data)
        
        #expect(repos.count == 1)
        #expect(repos[0].description == nil)
        #expect(repos[0].language == nil)
        #expect(repos[0].stargazersCount == nil)
    }
}
