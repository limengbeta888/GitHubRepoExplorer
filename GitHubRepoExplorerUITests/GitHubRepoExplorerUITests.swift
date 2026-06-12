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
        let navBar = app.navigationBars["GitHub Repos"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))
        
        // Switch to Bookmarks tab
        let bookmarksTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(bookmarksTab.waitForExistence(timeout: 5))
        bookmarksTab.tap()
        
        XCTAssertTrue(app.staticTexts["No Bookmarks"].waitForExistence(timeout: 5))
        
        // Switch back to Explore
        let exploreTab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(exploreTab.waitForExistence(timeout: 5))
        exploreTab.tap()
        
        XCTAssertTrue(navBar.exists)
    }

    func test_bookmark_flow() throws {
        let repoList = app.collectionViews["repo_list"]
        XCTAssertTrue(repoList.waitForExistence(timeout: 10))
        
        // 1. Find and tap a repo
        let godRepo = repoList.buttons["god"].firstMatch
        XCTAssertTrue(godRepo.waitForExistence(timeout: 10))
        godRepo.tap()
        
        // 2. Bookmark it
        let bookmarkButton = app.buttons["bookmark_button"]
        XCTAssertTrue(bookmarkButton.waitForExistence(timeout: 10))
        bookmarkButton.tap()
        
        // Verify state change
        XCTAssertTrue(app.buttons["bookmark_fill_button"].waitForExistence(timeout: 10))
        
        // 3. Go back and check Bookmarks tab
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons.element(boundBy: 1).tap()
        
        let bookmarkList = app.collectionViews["bookmark_list"]
        XCTAssertTrue(bookmarkList.waitForExistence(timeout: 10))
        XCTAssertTrue(bookmarkList.buttons["god"].exists)
        
        // 4. Remove via swipe
        let bookmarkedGod = bookmarkList.buttons["god"].firstMatch
        bookmarkedGod.swipeLeft()
        
        let removeButton = app.buttons["Remove"].firstMatch
        XCTAssertTrue(removeButton.waitForExistence(timeout: 5))
        removeButton.tap()
        
        // Verify empty state
        XCTAssertTrue(app.staticTexts["No Bookmarks"].waitForExistence(timeout: 5))
    }

    func test_grouping_flow() throws {
        let repoList = app.collectionViews["repo_list"]
        XCTAssertTrue(repoList.waitForExistence(timeout: 5))
        
        // Verify initial grouping (Owner Type)
        XCTAssertTrue(app.staticTexts["User"].exists)
        
        // Change grouping to Stars
        let groupButton = app.buttons["Group"]
        XCTAssertTrue(groupButton.waitForExistence(timeout: 5))
        groupButton.tap()
        
        let starsOption = app.buttons["Stars"]
        XCTAssertTrue(starsOption.waitForExistence(timeout: 5))
        starsOption.tap()
        
        // Verify star bands appear
        XCTAssertTrue(app.staticTexts["1000+ ★"].waitForExistence(timeout: 10))
    }
    
    func test_pull_to_refresh() throws {
        let repoList = app.collectionViews["repo_list"]
        XCTAssertTrue(repoList.waitForExistence(timeout: 5))
        
        // Perform pull to refresh
        let firstCell = repoList.cells.firstMatch
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 6.0))
        start.press(forDuration: 0, thenDragTo: finish)
        
        // Verify it still works (list is still there)
        XCTAssertTrue(repoList.exists)
    }
    
    func test_pagination_scroll() throws {
        let repoList = app.collectionViews["repo_list"]
        XCTAssertTrue(repoList.waitForExistence(timeout: 5))
        
        let initialCellCount = repoList.cells.count
        
        // Swipe up multiple times to reach the bottom and trigger load more
        repoList.swipeUp(velocity: .fast)
        repoList.swipeUp(velocity: .fast)
        repoList.swipeUp(velocity: .fast)
        
        // Check if more cells are loaded
        // We use a small wait because pagination is async
        let expectation = XCTestExpectation(description: "Wait for more cells")
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if repoList.cells.count > initialCellCount {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        timer.invalidate()
        
        XCTAssertTrue(repoList.cells.count > initialCellCount)
    }
}
