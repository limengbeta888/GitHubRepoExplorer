//
//  GitHubRepoExplorerUITests.swift
//  GitHubRepoExplorerUITests
//
//  Created by Meng Li on 10/06/2026.
//

import XCTest

final class GitHubRepoExplorerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func test_navigation_and_tabs() throws {
        // Start in Explore tab
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
        
        // Switch to Bookmarks tab
        // Use index-based selection as identifiers can be tricky in TabView
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["No Bookmarks"].waitForExistence(timeout: 5))
        
        // Switch back to Explore
        app.tabBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["GitHub Repos"].waitForExistence(timeout: 5))
    }

    func test_bookmark_flow() throws {
        // 1. Find a repo in the list (e.g., "god")
        let repoList = app.collectionViews["repo_list"]
        XCTAssertTrue(repoList.waitForExistence(timeout: 10))
        
        let godRepo = repoList.buttons["god"].firstMatch
        XCTAssertTrue(godRepo.waitForExistence(timeout: 10))
        
        // 2. Navigate to Detail
        godRepo.tap()
        XCTAssertTrue(app.navigationBars["god"].waitForExistence(timeout: 10))
        
        // 3. Bookmark it
        let bookmarkButton = app.buttons["bookmark_button"]
        XCTAssertTrue(bookmarkButton.waitForExistence(timeout: 10))
        bookmarkButton.tap()
        
        // Verify it changed to bookmark_fill_button
        XCTAssertTrue(app.buttons["bookmark_fill_button"].waitForExistence(timeout: 10))
        
        // 4. Go back to list
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 10))
        backButton.tap()
        
        // 5. Switch to Bookmarks tab
        let bookmarksTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(bookmarksTab.waitForExistence(timeout: 10))
        bookmarksTab.tap()
        
        let bookmarkList = app.collectionViews["bookmark_list"]
        XCTAssertTrue(bookmarkList.waitForExistence(timeout: 10))
        
        let bookmarkedGod = bookmarkList.buttons["god"].firstMatch
        XCTAssertTrue(bookmarkedGod.waitForExistence(timeout: 10))
        
        // 6. Remove bookmark via swipe
        bookmarkedGod.swipeLeft()
        
        let removeButton = app.buttons["Remove"].firstMatch
        XCTAssertTrue(removeButton.waitForExistence(timeout: 10))
        removeButton.tap()
        
        // Verify empty state
        XCTAssertTrue(app.staticTexts["No Bookmarks"].waitForExistence(timeout: 10))
    }

    func test_grouping_flow() throws {
        let repoList = app.collectionViews["repo_list"]
        XCTAssertTrue(repoList.waitForExistence(timeout: 5))
        
        // Verify initial grouping (Owner Type)
        XCTAssertTrue(app.staticTexts["User"].exists)
        XCTAssertTrue(app.staticTexts["Organization"].exists)
        
        // Change grouping to Stars
        app.buttons["Group"].tap()
        app.buttons["Stars"].tap()
        
        // Wait for fetch details indicator if needed, then check for star bands
        // Note: Mock data has specific star bands
        XCTAssertTrue(app.staticTexts["1000+ ★"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["100–999 ★"].exists)
    }
}
